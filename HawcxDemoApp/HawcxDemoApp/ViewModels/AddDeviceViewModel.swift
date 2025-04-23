//
//  AddDeviceViewModel.swift
//  HawcxDemoApp
//
//  Created by Agam Bhullar on 4/16/25.
//

import SwiftUI
import Combine
import HawcxFramework // Import SDK

enum AddDeviceFlowStage {
    case initial // Initial state with send button
    case sending // OTP is being requested
    case verification // OTP has been sent, user can enter code
}

@MainActor
class AddDeviceViewModel: ObservableObject, AddDeviceCallback { // Conforms to AddDeviceCallback
    @Published var flowStage: AddDeviceFlowStage = .initial
    // Email passed from LoginView (cannot be changed in this flow)
    @Published var email: String

    // UI State - Mimics SignUpViewModel
    @Published var otp: String = ""
    @Published var isVerifyButtonDisabled: Bool = true // For the OTP submit button
    @Published var showOtpField: Bool = false // Controls visibility of OTP input
    @Published var canResendOTP: Bool = false

    // Loading States - Mimics SignUpViewModel
    // isStartingFlow corresponds to SignUp's isSignUpLoading
    @Published var isStartingFlow: Bool = false
    @Published var isVerifyingOTP: Bool = false // Renamed from isVerifying
    @Published var isResendingOTP: Bool = false

    // Callbacks
    // Changed: Updated callback type to pass email for automatic login
    var onSuccessfulDeviceAdd: ((String) -> Void)? // Callback on final success

    // Dependencies
    weak var appViewModel: AppViewModel?
    private var addDeviceManager: AddDeviceManager // Correct SDK Manager for this flow
    private var cancellables = Set<AnyCancellable>()

    // Computed Properties
    private var isOtpValid: Bool { isValidOTP(otp) }

    // Initializer
    init(email: String, appViewModel: AppViewModel?) {
        self.email = email
        self.appViewModel = appViewModel
        self.addDeviceManager = AddDeviceManager(apiKey: Constants.apiKey) // Initialize correct manager

        if appViewModel != nil {
            setupBindings()
        }
    }

    // Bindings - Mimics SignUpViewModel for OTP verification button
    private func setupBindings() {
        $otp
            .map { [weak self] otp -> Bool in
                guard let self = self else { return true }
                // Disable if OTP invalid OR verifying/resending OR OTP field not shown yet
                return !self.isOtpValid || self.isVerifyingOTP || self.isResendingOTP || !self.showOtpField
            }
            .assign(to: \.isVerifyButtonDisabled, on: self)
            .store(in: &cancellables)
    }

    // MARK: - Actions - Mimics SignUpViewModel Actions
    
    func sendVerificationCode() {
        guard !isStartingFlow && !isVerifyingOTP && !isResendingOTP else { return }
        guard let appViewModel = appViewModel else { return }
        
        flowStage = .sending
        isStartingFlow = true
        showOtpField = false
        canResendOTP = false
        appViewModel.hideKeyboard()
        
        // Call the AddDeviceManager's entry point
        addDeviceManager.startAddDeviceFlow(userid: email, callback: self)
    }

    /// Resends the OTP by re-initiating the Add Device flow
    func resendOtp() {
        guard !isResendingOTP && !isVerifyingOTP else { return } // Prevent overlap
        guard let appViewModel = appViewModel else { return }

        isResendingOTP = true // Set resend loading state
        canResendOTP = false  // Disable resend button while resending
        appViewModel.hideKeyboard()

        // Re-call the main entry point to get a new OTP session
        addDeviceManager.startAddDeviceFlow(userid: email, callback: self)
    }

    /// Verifies the entered OTP (equivalent to SignUp's verify action)
    func verifyOtpButtonTapped() {
        guard !isVerifyingOTP else { return } // Prevent multiple verify attempts
        guard let appViewModel = appViewModel else { return }
        guard isOtpValid else {
            appViewModel.alertInfo = AlertInfo(title: "Invalid OTP", message: "Please enter a valid 6-digit OTP.")
            return
        }
        isVerifyingOTP = true // Set verify loading state
        isResendingOTP = false // Ensure resend loading is off
        appViewModel.hideKeyboard()

        // Call the AddDeviceManager's OTP handler
        addDeviceManager.handleVerifyOTP(otp: otp)
    }

    // MARK: - AddDeviceCallback Implementation - Mimics SignUpCallback Handling

    /// Called by AddDeviceManager on successful completion of add+verify steps.
    // Changed: Modified to pass email to callback for auto-login
    nonisolated func onAddDeviceSuccess() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            // Reset all loading states
            self.isStartingFlow = false
            self.isVerifyingOTP = false
            self.isResendingOTP = false
            
            // Wait a moment before initiating login
            self.onSuccessfulDeviceAdd?(self.email)
        }
    }

    /// Called by AddDeviceManager when OTP is successfully initiated.
    nonisolated func onGenerateOTPSuccess() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            // Reset relevant loading states
            self.isStartingFlow = false
            self.isResendingOTP = false
            // Update UI state
            self.flowStage = .verification
            self.showOtpField = true // Show OTP field now
            self.canResendOTP = true // Enable resend button
            self.appViewModel?.alertInfo = AlertInfo(
                title: "Verification Code Sent",
                message: "A verification code has been sent to \(self.email). Please check your email and enter the code below."
            )
            
        }
    }

    /// Called by AddDeviceManager when any error occurs during the flow.
    nonisolated func showError(addDeviceErrorCode: AddDeviceErrorCode, errorMessage: String) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            // Reset all loading states
            self.isStartingFlow = false
            self.isVerifyingOTP = false
            self.isResendingOTP = false
            
            if self.flowStage != .verification {
                self.flowStage = .initial
            }
            // Call enhanced error handler
            self.handleAddDeviceError(errorCode: addDeviceErrorCode, sdkErrorMessage: errorMessage)
        }
    }

    // MARK: - Enhanced Error Handling - Mimics SignUpViewModel's `handleSignUpError`

    /// Provides user-friendly feedback based on the AddDeviceErrorCode.
    private func handleAddDeviceError(errorCode: AddDeviceErrorCode, sdkErrorMessage: String) {
        guard let appViewModel = appViewModel else { return }

        var userFriendlyTitle = "Add Device Failed"
        // Use the specific helper function first
        var userFriendlyMessage = "An unknown error occurred. Please try again later."

        // Refine messages based on the specific error code for better UX
        switch errorCode {
        case .verifyOtpFailed:
            userFriendlyTitle = "Verification Failed"
            userFriendlyMessage = "The verification code you entered is incorrect or has expired. Please try again or request a new code."
            self.otp = "" // Clear OTP field
            self.canResendOTP = true // Allow resend

        case .generateOtpFailed:
            userFriendlyTitle = "Verification Code Error"
            userFriendlyMessage = "We couldn't generate a verification code. Please check your connection or try again later."
            self.showOtpField = false // Hide OTP field as initiation failed
            self.canResendOTP = false // Disable resend as initiation failed

        case .networkError:
            userFriendlyTitle = "Connection Error"
            userFriendlyMessage = "We couldn't connect to our servers. Please check your internet connection and try again."
            self.canResendOTP = true // Allow retry

        case .keychainSaveTokenFailed, .cryptoSaveFailed:
            userFriendlyTitle = "Device Storage Error"
            userFriendlyMessage = "We couldn't securely save device information. Please check your device settings and try again."
            // Don't necessarily reset UI, allow potential retry after fixing settings

        case .addUserDeviceApiFailed, .verifyDeviceApiFailed:
            userFriendlyTitle = "Registration Error"
            userFriendlyMessage = "There was an error registering this device with your account. Please try again."
            self.canResendOTP = true // Allow retry

        case .missingToken, .missingCrypto:
            userFriendlyTitle = "Incomplete Process"
            userFriendlyMessage = "Device addition process incomplete due to a server response error. Please try again."
            self.canResendOTP = true

        case .fingerprintError:
             userFriendlyTitle = "Device Security Error"
             userFriendlyMessage = "Failed to prepare unique device identifier. Ensure security features are enabled and try again."
             self.showOtpField = false // Hide OTP field as prerequisites failed
             self.canResendOTP = false

        case .stateError:
             userFriendlyTitle = "Internal Error"
             userFriendlyMessage = "An internal application error occurred. Please restart the Add Device process."
             // Dismissing might be appropriate here, handled by view/app

        case .unknownError:
            fallthrough
        default:
            userFriendlyTitle = "Error Adding Device"
            // Check original SDK message for more context if available
            if sdkErrorMessage.contains("internal server error") {
                userFriendlyTitle = "Server Error"
                userFriendlyMessage = "Our service is experiencing issues. Please try again later."
            } else if userFriendlyMessage.contains("unexpected error") { // Use default if SDK helper was generic
                 userFriendlyMessage = "An unexpected error occurred while adding the device. Please try again."
            }
            // If helper provided a specific message, userFriendlyMessage already holds it.
            self.canResendOTP = true // Allow retry for unknown errors
        }

        // Show the alert
        appViewModel.alertInfo = AlertInfo(title: userFriendlyTitle, message: userFriendlyMessage)
    }
}
