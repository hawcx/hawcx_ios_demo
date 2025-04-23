//
//  SignUpViewModel.swift
//  HawcxDemoApp
//
//  Updated on 4/15/25.
//

import SwiftUI
import Combine
import HawcxFramework

@MainActor
class SignUpViewModel: ObservableObject, SignUpCallback {
    @Published var prefilledEmail: String? = nil
    @Published var email: String = ""
    @Published var otp: String = ""
    @Published var isSignUpButtonDisabled: Bool = true
    @Published var isVerifyOtpButtonDisabled: Bool = true
    @Published var showOtpField: Bool = false // Controls visibility of OTP input
    @Published var canResendOTP: Bool = false
    
    // Button-specific loading states
    @Published var isSignUpLoading: Bool = false
    @Published var isVerifyingOTP: Bool = false
    @Published var isResendingOTP: Bool = false
    
    // Changed: Updated callback type to pass email for automatic login
    var onSuccessfulSignUpCompleted: ((String) -> Void)?
    
    var onUserAlreadyExists: ((String) -> Void)?
    
    weak var appViewModel: AppViewModel? // Use weak reference
    private var signUpManager: SignUp // SDK component instance
    private var cancellables = Set<AnyCancellable>()
    
    private var isEmailValid: Bool {
        isValidEmail(email)
    }
    private var isOtpValid: Bool {
        isValidOTP(otp)
    }
    
    init(appViewModel: AppViewModel?) {
        self.appViewModel = appViewModel
        self.signUpManager = SignUp(apiKey: Constants.apiKey)
        
        // Start in email entry state, not OTP state
        self.showOtpField = false
        self.otp = ""
        self.canResendOTP = false
        
        if appViewModel != nil {
            setupBindings()
        }
    }
    
    func resetState() {
        self.showOtpField = false
        self.otp = ""
        self.canResendOTP = false
        // Don't reset email if we have a prefilled one
        if self.prefilledEmail != nil && !self.email.isEmpty {
            self.email = self.prefilledEmail!
        }
    }
    
    private func setupBindings() {
        $email
            .map { [weak self] email -> Bool in
                guard let self = self else { return true }
                return !self.isEmailValid
            }
            .assign(to: \.isSignUpButtonDisabled, on: self)
            .store(in: &cancellables)
        
        $otp
            .map { [weak self] otp -> Bool in
                guard let self = self else { return true }
                return !self.isOtpValid
            }
            .assign(to: \.isVerifyOtpButtonDisabled, on: self)
            .store(in: &cancellables)
    }
    
    func signUpButtonTapped() {
        guard let appViewModel = appViewModel else { return }
        guard isEmailValid else {
            appViewModel.alertInfo = AlertInfo(title: "Invalid Email", message: "Please enter a valid email address.")
            return
        }
        
        // Set button-specific loading state instead of global loading
        isSignUpLoading = true
        appViewModel.hideKeyboard()
        
        signUpManager.signUp(userid: email, callback: self)
    }
    
    func verifyOtpButtonTapped() {
        guard let appViewModel = appViewModel else { return }
        guard isOtpValid else {
            appViewModel.alertInfo = AlertInfo(title: "Invalid OTP", message: "Please enter a valid 6-digit OTP.")
            return
        }
        
        // Set button-specific loading state instead of global loading
        isVerifyingOTP = true
        appViewModel.hideKeyboard()
        
        signUpManager.handleVerifyOTP(otp: otp, callback: self)
    }
    
    func changeEmail() {
        showOtpField = false
        canResendOTP = false  // Reset resend button visibility
        otp = "" // Clear OTP
    }
    
    func resendOtp() {
        guard let appViewModel = appViewModel else { return }
        guard isEmailValid else {
            appViewModel.alertInfo = AlertInfo(title: "Invalid Email", message: "Cannot resend OTP for an invalid email.")
            return
        }
        
        // Set button-specific loading state
        isResendingOTP = true
        appViewModel.hideKeyboard()
        
        signUpManager.signUp(userid: email, callback: self)
    }
    
    // Enhanced error handler
    nonisolated func showError(signUpErrorCode: SignUpErrorCode, errorMessage: String) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            // Reset all loading states
            self.isSignUpLoading = false
            self.isVerifyingOTP = false
            self.isResendingOTP = false
            
            // Use our enhanced error handler
            self.handleSignUpError(signUpErrorCode: signUpErrorCode, errorMessage: errorMessage)
        }
    }
    
    // Enhanced error handling method
    private func handleSignUpError(signUpErrorCode: SignUpErrorCode, errorMessage: String) {
        guard let appViewModel = appViewModel else { return }
        
        // Determine a user-friendly message based on the error code
        var userFriendlyTitle = "Sign Up Failed"
        var userFriendlyMessage = errorMessage
        
        switch signUpErrorCode {
        case .userAlreadyExists:
            userFriendlyTitle = "Account Already Exists"
            userFriendlyMessage = "An account with this email already exists. Please log in instead."
            
            // Changed: Pass email to callback to attempt login for existing user
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                self.onUserAlreadyExists?(self.email)
            }
            
        case .verifyOtpFailed:
            userFriendlyTitle = "Verification Failed"
            userFriendlyMessage = "The verification code you entered is incorrect or has expired. Please try again or request a new code."
            
            // Show OTP field again but clear the invalid OTP
            self.showOtpField = true
            self.otp = ""
            
        case .generateOtpFailed:
            userFriendlyTitle = "Verification Code Error"
            userFriendlyMessage = "We couldn't generate a verification code. Please try again later."
            
            self.showOtpField = false
            self.canResendOTP = false
            
        case .networkError:
            // Server error handling - provide more context and reassurance
            userFriendlyTitle = "Server Temporarily Unavailable"
            userFriendlyMessage = "We're experiencing technical difficulties with our service. This is likely a temporary issue that our team is working to resolve. Please try again in a few minutes."
            
            // Only reset UI if we haven't shown the OTP field yet
            if !self.showOtpField {
                self.showOtpField = false
                self.canResendOTP = false
            }
            
        case .keychainSaveFailed:
            userFriendlyTitle = "Device Storage Error"
            userFriendlyMessage = "We couldn't securely save your information. Please check your device settings and try again."
            
            self.showOtpField = false
            self.canResendOTP = false
            
        default:
            // For unexpected errors, check message content for server issues
            if errorMessage.contains("internal server error") {
                userFriendlyTitle = "Server Error"
                userFriendlyMessage = "Our service is experiencing issues. Please try again later. We apologize for the inconvenience."
            }
            
            self.showOtpField = false
            self.canResendOTP = false
        }
        
        // Show the appropriate alert to the user
        appViewModel.alertInfo = AlertInfo(title: userFriendlyTitle, message: userFriendlyMessage)
    }
    
    // Changed: Modified to pass email to callback for auto-login
    nonisolated func onSuccessfulSignUp() {
        Task { @MainActor [weak self] in
            guard let self = self, let appViewModel = self.appViewModel else { return }
            
            // Reset loading states
            self.isSignUpLoading = false
            self.isVerifyingOTP = false
            self.isResendingOTP = false
            
            self.onSuccessfulSignUpCompleted?(self.email)
        }
    }
    
    nonisolated func onGenerateOTPSuccess() {
        Task { @MainActor [weak self] in
            guard let self = self, let appViewModel = self.appViewModel else { return }
            
            // Reset loading states
            self.isSignUpLoading = false
            self.isResendingOTP = false
            
            self.showOtpField = true
            self.canResendOTP = true  // Enable resend button
            appViewModel.alertInfo = AlertInfo(title: "OTP Sent", message: "An OTP has been sent to your email.")
        }
    }
}
