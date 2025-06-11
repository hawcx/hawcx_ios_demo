//
//  AuthenticateViewModel.swift
//  HawcxDemoApp
//
//  Created for V4 SDK Integration.
//  Handles unified authentication (Login, SignUp, Add Device).
//
// AuthenticateViewModel.swift
import SwiftUI
import Combine
import LocalAuthentication
import HawcxFramework

@MainActor
class AuthenticateViewModel: ObservableObject, AuthV4Callback {

    // MARK: - Published Properties (UI State)
    @Published var email: String = ""
    @Published var otp: String = ""

    @Published var isEmailFieldFocused: Bool = false
    @Published var isOtpFieldFocused: Bool = false
    @Published var isOtpVisible: Bool = false

    @Published var isLoading: Bool = false
    @Published var isBiometricLoggingIn: Bool = false

    @Published var showBiometricButton: Bool = false
    @Published var isBiometricAvailable: Bool = false
    @Published var shouldShowBiometricEnablePrompt: Bool = false

    // MARK: - Computed Properties
    var isActionButtonDisabled: Bool {
        if isOtpVisible {
            return !isValidOTP(otp) || isLoading
        } else {
            return !isValidEmail(email) || isLoading
        }
    }

    var actionButtonText: String {
        if isLoading && !isBiometricLoggingIn {
            return "Processing..."
        }
        return isOtpVisible ? "Verify OTP" : "Authenticate"
    }
    
    var onSuccessfullyAuthenticatedAndLoggedIn: ((_ username: String) -> Void)?

    weak var appViewModel: AppViewModel?
    private var hawcxSDK: HawcxSDK
    private var cancellables = Set<AnyCancellable>()

    init(appViewModel: AppViewModel?) {
        self.appViewModel = appViewModel
        self.hawcxSDK = HawcxSDK(projectApiKey: Constants.apiKey)
        setupBindings()
        loadInitialEmail()
        checkBiometricAvailability()
    }

    private func setupBindings() {}

    func authenticateButtonTapped() {
        guard let appViewModel = appViewModel, !isLoading else { return }

        if isOtpVisible {
            guard isValidOTP(otp) else {
                appViewModel.showAlert(title: "Invalid OTP", message: "Please enter a valid 6-digit OTP.")
                return
            }
            print("[AuthenticateViewModel] Submitting OTP: \(otp) for email: \(email)")
            isLoading = true
            appViewModel.hideKeyboard()
            hawcxSDK.submitOtpV4(otp: otp)
        } else {
            guard isValidEmail(email) else {
                appViewModel.showAlert(title: "Invalid Email", message: "Please enter a valid email address.")
                return
            }
            print("[AuthenticateViewModel] Starting V4 authentication for: \(email)")
            isLoading = true
            appViewModel.hideKeyboard()
            hawcxSDK.authenticateV4(userid: email, callback: self)
        }
    }
    
    func changeEmail() {
        isOtpVisible = false
        otp = ""
        isEmailFieldFocused = true
    }

    func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        isBiometricAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        if isBiometricAvailable,
           let lastUser = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.lastUser),
           UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.biometricPrefix + lastUser) {
            showBiometricButton = true
        } else {
            showBiometricButton = false
        }
        print("[AuthenticateViewModel] Biometric Available: \(isBiometricAvailable), Show Button: \(showBiometricButton)")
    }

    func biometricButtonTapped() {
        guard let appViewModel = appViewModel, !isBiometricLoggingIn, !isLoading else { return }
        guard let lastUser = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.lastUser) else {
            appViewModel.showAlert(title: "Biometric Error", message: "No previous user found to log in with biometrics.")
            return
        }
        print("[AuthenticateViewModel] Attempting explicit biometric V4 authentication for: \(lastUser)")
        isBiometricLoggingIn = true
        isLoading = true
        appViewModel.hideKeyboard()
        email = lastUser
        authenticateWithBiometrics(lastUser)
    }

    func attemptAutomaticBiometricLogin() {
        print("[AuthenticateViewModel] Attempting automatic biometric V4 login check")
        guard isBiometricAvailable, !isBiometricLoggingIn, !isLoading else {
            print("[AuthenticateViewModel] Biometrics not available or already processing.")
            return
        }
        guard let lastUser = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.lastUser) else {
            print("[AuthenticateViewModel] No last user found, skipping biometric login.")
            return
        }
        guard UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.biometricPrefix + lastUser) else {
            print("[AuthenticateViewModel] Biometrics not enabled for user \(lastUser), skipping.")
            return
        }
        if appViewModel?.authenticationState == .loggedIn {
            print("[AuthenticateViewModel] Already logged in, skipping biometric login.")
            return
        }

        print("[AuthenticateViewModel] Attempting automatic biometric V4 authentication for: \(lastUser)")
        isBiometricLoggingIn = true
        isLoading = true
        email = lastUser
        authenticateWithBiometrics(lastUser)
    }

    private func authenticateWithBiometrics(_ userEmailToAuth: String) {
        let biometricService = BiometricService()
        biometricService.authenticate { [weak self] success, error in
            Task { @MainActor in
                guard let self = self else { return }
                if success {
                    print("[AuthenticateViewModel] Biometric hardware auth successful for \(userEmailToAuth). Calling SDK authenticateV4.")
                    self.hawcxSDK.authenticateV4(userid: userEmailToAuth, callback: self)
                } else {
                    print("[AuthenticateViewModel] Biometric hardware auth failed: \(error?.localizedDescription ?? "Unknown error")")
                    self.isLoading = false
                    self.isBiometricLoggingIn = false
                    if let laError = error as? LAError, laError.code != .userCancel && laError.code != .appCancel && laError.code != .systemCancel {
                        self.appViewModel?.showAlert(title: "Biometric Failed", message: error?.localizedDescription ?? "Could not verify biometrics.")
                    }
                }
            }
        }
    }

    func enableBiometrics() {
        guard let currentUserEmail = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.lastUser) else { return }
        let biometricService = BiometricService()
        
        biometricService.authenticate { [weak self] success, error in
            Task { @MainActor in
                guard let self = self else { return }
                if success {
                    UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.biometricPrefix + currentUserEmail)
                    // Use toast for successful enablement
                    self.appViewModel?.showToast(style: .success, message: "Biometric login enabled for \(currentUserEmail).")
                    self.showBiometricButton = true
                } else {
                    let errorMessage = error?.localizedDescription ?? "Verification failed"
                    self.appViewModel?.showAlert(title: "Biometrics Not Enabled", message: "Biometric verification failed: \(errorMessage)")
                }
                self.shouldShowBiometricEnablePrompt = false
                self.onSuccessfullyAuthenticatedAndLoggedIn?(currentUserEmail)
            }
        }
    }

    func declineBiometrics() {
        shouldShowBiometricEnablePrompt = false
        if let currentUserEmail = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.lastUser) {
             self.onSuccessfullyAuthenticatedAndLoggedIn?(currentUserEmail)
        }
    }
    
    func loadInitialEmail() {
        if let lastUser = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.lastUser) {
            email = lastUser
        }
    }

    nonisolated func onOtpRequired() {
        Task { @MainActor in
            print("[AuthenticateViewModel] AuthV4Callback: OTP Required for \(self.email)")
            self.isLoading = false
            self.isOtpVisible = true
            
            guard !Task.isCancelled else { return }
            self.isOtpFieldFocused = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // MODIFIED: Use showToast instead of showAlert for OTP required message
                self.appViewModel?.showToast(style: .info, message: "Verification code sent to \(self.email)")
            }
        }
    }

//    nonisolated func onAuthSuccess(accessToken: String?, refreshToken: String?, isLoginFlow: Bool) {
//        Task { @MainActor [weak self] in
//            guard let strongSelf = self else { return }
//            
//            let currentFlowEmail = strongSelf.email
//            
//            if isLoginFlow {
//                print("[AuthenticateViewModel] AuthV4Callback: Login Flow Success for \(currentFlowEmail). AccessToken: \(accessToken != nil)")
//                strongSelf.isLoading = false
//                strongSelf.isBiometricLoggingIn = false
//                strongSelf.isOtpVisible = false
//                strongSelf.otp = ""
//                
//                guard let accToken = accessToken else {
//                    strongSelf.reportCriticalError("Login flow success reported (isLoginFlow=true) but the access token is missing for \(currentFlowEmail).")
//                    return
//                }
//                
//                if refreshToken == nil {
//                    print("[AuthenticateViewModel] Note: Refresh token was not provided by the SDK in this callback for user \(currentFlowEmail).")
//                }
//                
//                UserDefaults.standard.set(currentFlowEmail, forKey: Constants.UserDefaultsKeys.lastUser)
//                print("[AuthenticateViewModel] Saved last user to UserDefaults: \(currentFlowEmail)")
//                
//                strongSelf.postAuthResult(success: true)
//                strongSelf.appViewModel?.clearAlertsAndToast() // Clear any existing notifications
//                
//                if strongSelf.isBiometricAvailable && !UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.biometricPrefix + currentFlowEmail) {
//                    print("[AuthenticateViewModel] Biometrics available but not enabled for \(currentFlowEmail). Showing prompt.")
//                    Task {
////                        try? await Task.sleep(nanoseconds: 300_000_000)
//                        guard !Task.isCancelled else { return }
//                        strongSelf.shouldShowBiometricEnablePrompt = true
//                    }
//                } else {
//                    // MODIFIED: Use showToast for login success message
//                    strongSelf.appViewModel?.showToast(style: .success, message: "Login successful! Welcome, \(currentFlowEmail).")
//                    Task {
//                        try? await Task.sleep(nanoseconds: 1_500_000_000) // Wait for toast to be seen
//                        guard !Task.isCancelled else { return }
//                        strongSelf.appViewModel?.clearAlertsAndToast()
//                        strongSelf.onSuccessfullyAuthenticatedAndLoggedIn?(currentFlowEmail)
//                    }
//                }
//            } else {
//                print("[AuthenticateViewModel] AuthV4Callback: Device Registration Flow Success for \(currentFlowEmail). Now initiating login.")
//                strongSelf.isLoading = true
//                strongSelf.isOtpVisible = false
//                strongSelf.otp = ""
//                // MODIFIED: Use showToast for registration complete message
//                strongSelf.appViewModel?.showToast(style: .info, message: "Device registered. Logging you in...")
//                
//                Task {
//                    do {
//                        try await Task.sleep(nanoseconds: 1_000_000_000) // Shorter delay for toast
//                        guard !Task.isCancelled else { return }
//                        print("[AuthenticateViewModel] Automatically re-initiating authenticateV4 for LOGIN after registration of \(currentFlowEmail).")
//                        strongSelf.hawcxSDK.authenticateV4(userid: currentFlowEmail, callback: strongSelf)
//                    } catch {
//                        strongSelf.reportCriticalError("Failed to schedule re-authentication for login after registration for \(currentFlowEmail). Error: \(error)")
//                    }
//                }
//            }
//        }
//    }
    
    nonisolated func onAuthSuccess(accessToken: String?, refreshToken: String?, isLoginFlow: Bool) {
        Task { @MainActor [weak self] in
            guard let strongSelf = self else { return }
            
            let currentFlowEmail = strongSelf.email
            
            if isLoginFlow {
                print("[AuthenticateViewModel] AuthV4Callback: Login Flow Success for \(currentFlowEmail). AccessToken: \(accessToken != nil)")
                strongSelf.isLoading = false
                strongSelf.isBiometricLoggingIn = false
                strongSelf.isOtpVisible = false
                strongSelf.otp = ""
                
                guard let accToken = accessToken else {
                    strongSelf.reportCriticalError("Login flow success reported (isLoginFlow=true) but the access token is missing for \(currentFlowEmail).")
                    return
                }
                
                if refreshToken == nil {
                    print("[AuthenticateViewModel] Note: Refresh token was not provided by the SDK in this callback for user \(currentFlowEmail).")
                }
                
                UserDefaults.standard.set(currentFlowEmail, forKey: Constants.UserDefaultsKeys.lastUser)
                print("[AuthenticateViewModel] Saved last user to UserDefaults: \(currentFlowEmail)")
                
                strongSelf.postAuthResult(success: true)
                strongSelf.appViewModel?.clearAlertsAndToast()    // clear any stale alerts/toasts
                
                if strongSelf.isBiometricAvailable
                   && !UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.biometricPrefix + currentFlowEmail) {
                    
                    print("[AuthenticateViewModel] Biometrics available but not enabled for \(currentFlowEmail). Showing prompt.")
                    Task {
                        guard !Task.isCancelled else { return }
                        strongSelf.shouldShowBiometricEnablePrompt = true
                    }
                    
                } else {
                    // 1️⃣ show the success toast immediately
                    strongSelf.appViewModel?.showToast(
                        style: .success,
                        message: "Login successful! Welcome, \(currentFlowEmail)."
                    )
                    
                    // 2️⃣ navigate right away
                    strongSelf.onSuccessfullyAuthenticatedAndLoggedIn?(currentFlowEmail)
                    
                    // 3️⃣ after the toast’s own duration, clear just the toast
                    Task {
                        let toastDuration = strongSelf.appViewModel?.toast?.duration ?? 3.0
                        try? await Task.sleep(nanoseconds: UInt64(toastDuration * 1_000_000_000))
                        guard !Task.isCancelled else { return }
                        strongSelf.appViewModel?.clearToast()
                    }
                }
                
            } else {
                // Device-registration flow → then auto-login
                print("[AuthenticateViewModel] AuthV4Callback: Device Registration Flow Success for \(currentFlowEmail). Now initiating login.")
                strongSelf.isLoading = true
                strongSelf.isOtpVisible = false
                strongSelf.otp = ""
                
                strongSelf.appViewModel?.showToast(
                    style: .info,
                    message: "Device registered. Logging you in..."
                )
                
                Task {
                    do {
                        try await Task.sleep(nanoseconds: 1_000_000_000) // give the toast a moment
                        guard !Task.isCancelled else { return }
                        print("[AuthenticateViewModel] Automatically re-initiating authenticateV4 for LOGIN after registration of \(currentFlowEmail).")
                        strongSelf.hawcxSDK.authenticateV4(userid: currentFlowEmail, callback: strongSelf)
                    } catch {
                        strongSelf.reportCriticalError("Failed to schedule re-authentication for login after registration for \(currentFlowEmail). Error: \(error)")
                    }
                }
            }
        }
    }

    nonisolated func onError(errorCode: AuthV4ErrorCode, errorMessage: String) {
        Task { @MainActor [weak self] in
            guard let strongSelf = self else { return }
            
            let currentFlowEmail = strongSelf.email
            print("[AuthenticateViewModel] AuthV4Callback: Error for \(currentFlowEmail). Code: \(errorCode.rawValue), Message: \(errorMessage)")
            strongSelf.isLoading = false
            strongSelf.isBiometricLoggingIn = false
            if errorCode != .otpVerificationFailed {
                strongSelf.isOtpVisible = false
            }
            
            strongSelf.postAuthResult(success: false)
            strongSelf.appViewModel?.clearAlertsAndToast()
            // Errors still use the modal alert
            strongSelf.appViewModel?.showAlert(title: "Authentication Failed", message: "\(errorMessage) (Code: \(errorCode.rawValue))")
        }
    }
    
    private func reportCriticalError(_ message: String) {
        print("[AuthenticateViewModel] CRITICAL ERROR: \(message)")
        isLoading = false
        isBiometricLoggingIn = false
        isOtpVisible = false
        postAuthResult(success: false)
        appViewModel?.clearAlertsAndToast()
        appViewModel?.showAlert(title: "Critical Error", message: "An unexpected issue occurred. Please try again. (\(message))")
    }

    private func postAuthResult(success: Bool) {
        print("[AuthenticateViewModel] Posting auth result notification: \(success ? "success" : "failure")")
        NotificationCenter.default.post(
            name: .authLoginResult,
            object: nil,
            userInfo: ["success": success, "email": email]
        )
    }
}
