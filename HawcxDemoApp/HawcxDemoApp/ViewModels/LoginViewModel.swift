//
//  LoginViewModel.swift
//  HawcxDemoApp
//
//  Updated 4/16/25
//

import SwiftUI
import Combine
import LocalAuthentication
import HawcxFramework

@MainActor
class LoginViewModel: ObservableObject, SignInCallback { // REMOVED AddDeviceCallback
    
    // MARK: - Published Properties (UI State)
    @Published var email: String = ""
    @Published var emailForSignUp: String? = nil
    @Published var isLoginButtonDisabled: Bool = true
    @Published var showBiometricButton: Bool = false
    @Published var isBiometricAvailable: Bool = false
    @Published var shouldShowBiometricEnablePrompt: Bool = false
    @Published var isLoggingIn: Bool = false
    @Published var isBiometricLoggingIn: Bool = false
    
    // MARK: Navigation State for Add Device Flow
    @Published var navigateToAddDeviceView: Bool = false
    @Published var emailForAddDevice: String? = nil // Email to pass to AddDeviceView
    
    // MARK: - Navigation Callbacks (Set by View)
    var onSignUpRequested: (() -> Void)?
    var onLoginSuccess: ((String) -> Void)?
    
    // MARK: - Dependencies
    weak var appViewModel: AppViewModel?
    private var signInManager: SignIn // SDK instance for Sign In
    // private var addDeviceManager: AddDeviceManager // REMOVED - Unused here
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    private var isEmailValid: Bool { isValidEmail(email) }
    
    // MARK: - Initializer
    init(appViewModel: AppViewModel?) {
        self.appViewModel = appViewModel
        self.signInManager = SignIn(apiKey: Constants.apiKey)
        // self.addDeviceManager = AddDeviceManager(apiKey: Constants.apiKey) // REMOVED
        setupBindings()
        checkBiometricAvailability()
        loadInitialEmail()
    }
    
    // MARK: - Bindings (No change)
    private func setupBindings() {
        $email
            .map { !$0.isEmpty && isValidEmail($0) }
            .map { !$0 }
            .assign(to: \.isLoginButtonDisabled, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Biometric Handling
    func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        isBiometricAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        // Show biometric button only if available AND enabled for the last user
        if isBiometricAvailable,
           let lastUser = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.lastUser),
           UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.biometricPrefix + lastUser) {
            showBiometricButton = true
        } else {
            showBiometricButton = false
        }
    }
    
    func biometricButtonTapped() {
        guard let appViewModel = appViewModel, !isBiometricLoggingIn else { return }
        guard let lastUser = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.lastUser) else {
            appViewModel.alertInfo = AlertInfo(title: "Biometric Error", message: "No previous user found.")
            return
        }
        isBiometricLoggingIn = true
        appViewModel.hideKeyboard()
        authenticateWithBiometrics(lastUser)
    }
    
    func attemptAutomaticBiometricLogin() {
        guard isBiometricAvailable, !isBiometricLoggingIn else { return }
        guard let lastUser = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.lastUser),
              UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.biometricPrefix + lastUser) else {
            return // Don't attempt if not enabled
        }
        isBiometricLoggingIn = true
        authenticateWithBiometrics(lastUser)
    }
    
    func enableBiometrics() {
        guard let lastUser = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.lastUser) else { return }
        
        // Create biometric service instance
        let biometricService = BiometricService()
        
        // First verify with biometrics before enabling the feature
        biometricService.authenticate { [weak self] success, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                if success {
                    // Biometric authentication successful, enable for future logins
                    UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.biometricPrefix + lastUser)
                    self.appViewModel?.showAlert(title: "Biometrics Enabled", message: "Biometric login is now active.")
                } else {
                    // Biometric authentication failed
                    if let error = error as? LAError, error.code == .userCancel {
                        // User canceled - treat as declining the feature
                        self.appViewModel?.showAlert(title: "Biometrics Not Enabled", message: "Biometric verification was canceled.")
                    } else {
                        // Other biometric errors
                        let errorMessage = error?.localizedDescription ?? "Verification failed"
                        self.appViewModel?.showAlert(title: "Biometrics Not Enabled", message: "Biometric verification failed: \(errorMessage)")
                    }
                }
                
                // Hide the prompt and proceed to home view in either case
                self.shouldShowBiometricEnablePrompt = false
                
                // Short delay before navigating to home
                try? await Task.sleep(nanoseconds: 500_000_000) // 1 second delay
                self.onLoginSuccess?(lastUser) // Proceed to home
            }
        }
    }
    
    func declineBiometrics() {
        shouldShowBiometricEnablePrompt = false
        if let lastUser = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.lastUser) {
            // Short delay before navigating to home
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.3 second delay
                onLoginSuccess?(lastUser) // Proceed to home
            }
        }
    }
    
    private func authenticateWithBiometrics(_ userEmail: String) {
        let context = LAContext()
        let reason = "Log in to your Hawcx account"
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
            Task { @MainActor in
                guard let self = self else { return }
                if success {
                    self.signInManager.signIn(userid: userEmail, callback: self)
                } else {
                    self.isBiometricLoggingIn = false // Reset loading
                    // Show error only for explicit taps, not automatic attempts or user cancel
                    if !self.email.isEmpty, let error = authenticationError as? LAError, ![.userCancel, .appCancel, .systemCancel].contains(error.code) {
                        self.appViewModel?.alertInfo = AlertInfo(title: "Biometric Failed", message: error.localizedDescription)
                    }
                }
            }
        }
    }
    
    // MARK: - Standard Login Action
    func loginButtonTapped() {
        guard let appViewModel = appViewModel, !isLoggingIn else { return }
        guard isEmailValid else {
            appViewModel.alertInfo = AlertInfo(title: "Invalid Email", message: "Please enter a valid email address.")
            return
        }
        isLoggingIn = true
        appViewModel.hideKeyboard()
        signInManager.signIn(userid: email, callback: self)
    }
    
    func loginWithEmail(_ email: String, isAutomatic: Bool = true) {
        // Set the email
        self.email = email
        
        // Only proceed if not already logging in
        guard !isLoggingIn && !isBiometricLoggingIn else {
            // Post failure notification
            postLoginResult(success: false)
            return
        }
        
        if isAutomatic {
            // For automatic login, skip validation and proceed directly
            isLoggingIn = true
            appViewModel?.hideKeyboard()
            
            // Call SDK directly
            signInManager.signIn(userid: email, callback: self)
        } else {
            // For manual login, use standard flow with validation
            loginButtonTapped()
        }
    }
    
    // Method to post login result notification
    private func postLoginResult(success: Bool) {
        // Post on main thread for consistency
        Task { @MainActor in
            NotificationCenter.default.post(
                name: Notification.Name("AuthLoginResult"),
                object: nil,
                userInfo: ["success": success]
            )
        }
    }
    
    // MARK: - Utility
    func loadInitialEmail() {
        if let lastUser = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.lastUser) {
            email = lastUser
        }
    }
    
    // MARK: - SignInCallback Implementation
    
    /// Handles errors received from the SDK during the sign-in attempt.
    nonisolated func showError(signInErrorCode: SignInErrorCode, errorMessage: String) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.isLoggingIn = false
            self.isBiometricLoggingIn = false
            
            // Post failure notification
            self.postLoginResult(success: false)
            
            // Use the internal helper to decide how to present the error
            self.handleLoginError(signInErrorCode: signInErrorCode, sdkErrorMessage: errorMessage)
        }
    }
    
    /// Called by the SDK when login fails in a way that requires adding the current device.
    nonisolated func initiateAddDeviceRegistrationFlow(for userid: String) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.isLoggingIn = false
            self.isBiometricLoggingIn = false
            self.emailForAddDevice = userid
            
            // Show an alert first to explain what's happening
            self.appViewModel?.alertInfo = AlertInfo(
                title: "Device Registration Required",
                message: "This device needs to be registered with your account before you can log in. We'll send a verification code to \(userid)."
            )
            
            self.navigateToAddDeviceView = true
        }
    }
    
    private func showAlertAndNavigateToSignUp(title: String = "Account Not Found", message: String = "No account exists with this email. Please sign up first.") {
        // Show alert
        appViewModel?.showAlert(title: title, message: message)
        
        // Navigate to signup after delay
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 second delay
            self.onSignUpRequested?() // Navigate to signup
        }
    }
    
    // MARK: ADDED Implementation for new callback
    nonisolated func navigateToRegistration(for userid: String) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            // Reset loading states
            self.isLoggingIn = false
            self.isBiometricLoggingIn = false
            
            // Use the unified method
            self.showAlertAndNavigateToSignUp()
        }
    }
    
    // Success handler
    nonisolated func onSuccessfulLogin(_ loggedInEmail: String) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.isLoggingIn = false
            self.isBiometricLoggingIn = false
            UserDefaults.standard.set(loggedInEmail, forKey: Constants.UserDefaultsKeys.lastUser)
            
            // Post success notification first
            self.postLoginResult(success: true)
            
            // Clear any loading alert before showing biometric prompt
            self.appViewModel?.clearAlerts()
            
            // Short delay before continuing with the login flow
//            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            
            if self.isBiometricAvailable && !UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.biometricPrefix + loggedInEmail) {
                self.shouldShowBiometricEnablePrompt = true
            } else {
                self.onLoginSuccess?(loggedInEmail) // Triggers AppViewModel update to navigate to home
            }
        }
    }
    
    /// Legacy callback, potentially unused in V3.
    nonisolated func showEmailSignInScreen() {
        Task { @MainActor [weak self] in
            self?.isLoggingIn = false
            self?.isBiometricLoggingIn = false
        }
    }
    
    // MARK: - Private Error Handling Helper
    /// Determines the appropriate UI action (alert or navigation) based on the sign-in error.
    private func handleLoginError(signInErrorCode: SignInErrorCode, sdkErrorMessage: String) {
        guard let appViewModel = appViewModel else { return }
        
        var title = "Login Failed"
        // Determine message based on code, replicating SDK helper logic
        var message: String
        switch signInErrorCode {
        case .userNotFound:
            showAlertAndNavigateToSignUp()
            return // Exit early
            
        case .missingKeychainData:
            title = "Device Setup Required"
            message = "Account data needs to be set up on this device. Please proceed to add this device."
        case .addDeviceRequired:
            title = "Add This Device"
            message = "This device isn't registered with your account. Please follow the steps to add it."
        case .invalidDeviceToken:
            title = "Device Not Recognized"
            message = "Device authorization is invalid or expired. Please add this device again."
        case .networkError:
            title = "Connection Error"
            message = "A network error occurred. Please check connection."
        case .v3GenerateCipherFailed, .cipherGenerateFailed:
            title = "Security Check Failed"
            message = "Failed to initiate secure login."
        case .v3VerifyCipherFailed, .verificationFailed:
            title = "Security Check Failed"
            message = "Login verification failed."
        case .keychainSaveFailed: // Error reported by SDK if it failed to save tokens
            title = "Session Error"
            message = "Could not securely save login session."
        case .clientCryptoError:
            title = "Security Calculation Error"
            message = "A security calculation error occurred."
        case .dataPreparationError:
            title = "Internal Error"
            message = "An internal error occurred preparing device data."
            //        case .invalidInput:
            //            title = "Invalid Input"
            //            message = "Invalid input provided for login."
        case .deviceIDError:
            title = "Device Error"
            message = "Could not verify device identity."
        case .unknownError:
            fallthrough
        default:
            title = "Login Failed"
            message = sdkErrorMessage.isEmpty ? "An unexpected error occurred." : sdkErrorMessage
            if message.lowercased().contains("internal server error") { title = "Server Error" }
        }
        // Show the alert
        appViewModel.alertInfo = AlertInfo(title: title, message: message)
    }
}
