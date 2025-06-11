//
//  WebLoginViewModel.swift
//  HawcxDemoApp
//
//  Updated for better state management and error handling
//

// HawcxDemoApp/ViewModels/WebLoginViewModel.swift
import SwiftUI
import Combine
import HawcxFramework // Ensure SDK is imported

@MainActor
class WebLoginViewModel: ObservableObject, WebLoginCallback {
    // State management
    @Published var pin: String = ""
    @Published var isSubmitButtonDisabled: Bool = true
    @Published var showManualEntry: Bool = false
    @Published var showApprovalScreen: Bool = false
    // *** UPDATED: Explicitly use SDK's SessionDetails type ***
    @Published var sessionDetails: HawcxFramework.SessionDetails?

    // Action-specific loading states
    @Published var isPinSubmitting: Bool = false
    @Published var isApproving: Bool = false
    @Published var isDenying: Bool = false
    @Published var isLoading: Bool = false // Combined loading state

    // Callbacks
    var onSuccessCallback: (() -> Void)?
    var onShowQRScanner: (() -> Void)?
    weak var appViewModel: AppViewModel?
    private var hawcxSDK: HawcxSDK
    private var cancellables = Set<AnyCancellable>()

    init(appViewModel: AppViewModel?) {
        self.appViewModel = appViewModel
        self.hawcxSDK = HawcxSDK(projectApiKey: Constants.apiKey)
        if appViewModel != nil {
            setupBindings()
        } else {
            print("Warning: WebLoginViewModel initialized without AppViewModel.")
        }
    }

    convenience init() {
        self.init(appViewModel: nil)
    }

    private func setupBindings() {
        // Update binding to check against combined isLoading state
        $pin
            .combineLatest($isLoading) // Combine with isLoading
            .map { pin, loading in
                // Disable if pin is invalid OR if any operation is loading
                return !(pin.count == 7 && pin.allSatisfy { $0.isNumber }) || loading
            }
            .assign(to: \.isSubmitButtonDisabled, on: self)
            .store(in: &cancellables)

        // Keep the isLoading combination
        Publishers.CombineLatest3($isPinSubmitting, $isApproving, $isDenying)
            .map { $0 || $1 || $2 }
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
    }

    // isPinValid is now implicitly handled in the binding above
    // private var isPinValid: Bool { ... } // Can be removed if not used elsewhere

    // MARK: - User Actions

    func manualButtonTapped() {
        withAnimation { showManualEntry = true }
    }

    func scanQrButtonTapped() {
        onShowQRScanner?()
    }

    func submitPinButtonTapped() {
        guard let appViewModel = appViewModel else { return }
        // Use the binding's check implicitly or add explicit check if needed
        guard !isSubmitButtonDisabled else {
             if !(pin.count == 7 && pin.allSatisfy { $0.isNumber }) {
                 appViewModel.alertInfo = AlertInfo(title: "Invalid PIN", message: "Please enter a valid 7-digit PIN code.")
             } // Otherwise, it's disabled due to loading state, no alert needed
            return
        }
        print("[WebLoginViewModel] Submitting PIN: \(pin)")

        isPinSubmitting = true
        appViewModel.hideKeyboard()

        // Call SDK without accessToken (correct)
        hawcxSDK.webLogin(pin: pin, callback: self)
    }

    func approveWebLogin() {
        guard let appViewModel = appViewModel, !isApproving, !isDenying else { return } // Prevent double taps

        // Retrieve the webToken saved by the SDK's webLogin method
        guard let webToken = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.webToken) else {
            print("[WebLoginViewModel] Missing web token for approval (looked in UserDefaults key: \(Constants.UserDefaultsKeys.webToken))")
            appViewModel.alertInfo = AlertInfo(title: "Session Error", message: "Web login session token not found. Please try submitting the PIN again.")
            return // Don't set isApproving if token is missing
        }

        print("[WebLoginViewModel] Approving web login with token: \(webToken.prefix(6))...")
        isApproving = true

        // Call SDK without accessToken (correct)
        hawcxSDK.webApprove(token: webToken, callback: self)
    }

    func denyWebLogin() {
         guard !isDenying, !isApproving else { return } // Prevent double taps
         print("[WebLoginViewModel] User denied web login")
         isDenying = true

         // Clear session data from UserDefaults
         UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.webToken)
         // *** Use the correct key used by the SDK ***
         UserDefaults.standard.removeObject(forKey: "sessionDetails") // SDK saves under "sessionDetails"

         withAnimation {
             showApprovalScreen = false
             showManualEntry = false
             pin = ""
             sessionDetails = nil
         }

         appViewModel?.alertInfo = AlertInfo(title: "Login Denied", message: "Web login request has been denied.")

         // Slight delay before resetting state to allow animation/alert
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
             self.isDenying = false
         }
     }

    // MARK: - Helper Methods

    private func handleWebLoginError(errorCode: WebLoginErrorCode, errorMessage: String) {
        // (Error handling logic remains the same as previous correct version)
        print("[WebLoginViewModel] SDK Error: \(errorCode) - \(errorMessage)")
        var userFriendlyTitle = "Web Login Failed"
        var userFriendlyMessage = errorMessage // Default to SDK message

        switch errorCode {
        case .invalidPin:
            userFriendlyTitle = "Invalid PIN"
            userFriendlyMessage = "The PIN entered is invalid or expired. Please try again."
        case .failedApprove:
            userFriendlyTitle = "Approval Failed"
            userFriendlyMessage = "Failed to approve the web login request. The session might have expired."
        case .networkError:
            userFriendlyTitle = "Connection Error"
            userFriendlyMessage = "A network error occurred. Please check your connection."
        case .unknownError:
            if errorMessage.lowercased().contains("user session invalid") {
                 userFriendlyTitle = "Session Error"
                 userFriendlyMessage = errorMessage
            } else if errorMessage.lowercased().contains("internal server error") {
                userFriendlyTitle = "Server Error"
                userFriendlyMessage = "A server error occurred. Please try again later."
            } else {
                userFriendlyTitle = "Error"
                userFriendlyMessage = "An unexpected error occurred. Please try again."
            }
        @unknown default:
            fatalError()
        }
        appViewModel?.alertInfo = AlertInfo(title: userFriendlyTitle, message: userFriendlyMessage)
    }

    // MARK: - WebLoginCallback methods

    nonisolated func onSuccess() {
        print("[WebLoginViewModel] SDK onSuccess received.")
        Task { @MainActor [weak self] in
            guard let self = self else { return }

            // --- Success from webLogin (PIN submit) ---
            if self.isPinSubmitting {
                self.isPinSubmitting = false // Reset before potential UI changes
                print("[WebLoginViewModel] PIN submission successful.")

                // *** Use the correct key used by the SDK to save details ***
                if let sessionData = UserDefaults.standard.data(forKey: "sessionDetails") {
                    do {
                        let decoder = JSONDecoder()
                        // *** Decode the NEW SDK SessionDetails structure ***
                        let decodedDetails = try decoder.decode(HawcxFramework.SessionDetails.self, from: sessionData)
                        self.sessionDetails = decodedDetails
                        print("[WebLoginViewModel] Successfully decoded NEW SessionDetails structure.")
                        // Log some key fields using the new structure and derived properties
                        print("  > Device Type (Derived): \(decodedDetails.derivedDeviceType ?? "N/A")")
                        print("  > OS (Derived): \(decodedDetails.derivedOsDetails ?? "N/A")")
                        print("  > Browser (Derived): \(decodedDetails.derivedBrowserWithVersion ?? "N/A")")
                        print("  > Location (Derived): \(decodedDetails.derivedLocation ?? "N/A")")
                        print("  > IP: \(decodedDetails.ipDetails ?? "N/A")")
                        print("  > ISP: \(decodedDetails.isp ?? "N/A")")
                        print("  > Device ID: \(decodedDetails.deviceId ?? "N/A")")
                        print("  > FP Version: \(decodedDetails.deviceInfo?.fpVersion ?? "N/A")")

                        withAnimation { self.showApprovalScreen = true }

                    } catch {
                        print("[WebLoginViewModel] Error decoding NEW SessionDetails structure: \(error)")
                        // Log the raw data if decoding fails
                         if let rawString = String(data: sessionData, encoding: .utf8) {
                             print("[WebLoginViewModel] Raw sessionDetails data that failed decoding: \(rawString)")
                         }
                        self.appViewModel?.alertInfo = AlertInfo(title: "PIN Verified", message: "PIN verified, but failed to load session details. \(error.localizedDescription)")
                        self.pin = ""
                        withAnimation { self.showManualEntry = false } // Go back to options
                    }
                } else {
                    // Handle case where sessionDetails might be nil or not saved
                    print("[WebLoginViewModel] PIN success, but no session details found in UserDefaults (key: 'sessionDetails').")
                    self.appViewModel?.alertInfo = AlertInfo(title: "PIN Verified", message: "PIN verified, but session details unavailable from server.")
                    self.pin = ""
                    withAnimation { self.showManualEntry = false } // Go back to options
                }

            // --- Success from webApprove ---
            } else if self.isApproving {
                print("[WebLoginViewModel] Web login approval successful.")
                self.isApproving = false
                self.appViewModel?.alertInfo = AlertInfo(title: "Approved", message: "Web login successfully approved!")
                // Navigate back after a delay
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 sec delay
                    self.pin = ""
                    self.sessionDetails = nil // Clear details
                    withAnimation {
                        self.showApprovalScreen = false
                        self.showManualEntry = false
                    }
                    self.onSuccessCallback?() // Trigger navigation dismissal
                }
            } else {
                print("[WebLoginViewModel] SDK onSuccess received in unexpected state (neither submitting PIN nor approving).")
                // Reset all loading states just in case
                self.isPinSubmitting = false
                self.isApproving = false
            }
        }
    }

    nonisolated func showError(webLoginErrorCode: WebLoginErrorCode, errorMessage: String) {
        print("[WebLoginViewModel] SDK showError received: \(webLoginErrorCode)")
        Task { @MainActor [weak self] in
            guard let self = self else { return }

            let wasApproving = self.isApproving // Check state *before* resetting

            // Reset loading states
            self.isPinSubmitting = false
            self.isApproving = false
            // Don't reset isDenying, denyWebLogin handles it

            self.handleWebLoginError(errorCode: webLoginErrorCode, errorMessage: errorMessage)

            if wasApproving {
                // If approval failed, go back to the options screen
                withAnimation {
                    self.showApprovalScreen = false
                    self.showManualEntry = false // Ensure options are shown
                    self.pin = ""
                    self.sessionDetails = nil
                }
            } else {
                 // If PIN submission failed, just clear the PIN field
                 self.pin = ""
                 // Keep manual entry screen visible for retry
            }
        }
    }
}
