import SwiftUI

struct SignUpView: View {
    @StateObject private var viewModel: SignUpViewModel
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var sharedAuthManager: SharedAuthManager
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isOtpFocused: Bool
    @FocusState private var isEmailFieldFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
    @State private var isKeyboardVisible = false
    
    init(viewModel: SignUpViewModel, appViewModel: AppViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 20) {
                        
                        //                        Spacer()
                        
                        Image("Hawcx_Logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 200)
                            .clipped()
                            .overlay (
                                Text("HAWCX")
                                    .font(.system(size: 60, weight: .medium, design: .serif))
                                    .padding(.top, 150)
                                
                                
                            )
                            .padding(.bottom, 50)
                        
                        //                        Text("Create Account")
                        //                            .font(.largeTitle)
                        //                            .fontWeight(.bold)
                        
                        if viewModel.showOtpField {
                            Text("Enter your email to get started")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                        } else {
                            Text("Enter the OTP sent to your email")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        
                        TextField("Email Address", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isEmailFieldFocused ? Color.blue : Color.gray.opacity(0.5), lineWidth: isEmailFieldFocused ? 2 : 1)
                            )
                            .focused($isEmailFieldFocused)
                            .padding(.horizontal)
                            .disabled(viewModel.showOtpField) // Disable email field when showing OTP
                            .opacity(viewModel.showOtpField ? 0.5 : 1.0) // Dim email field
                        
                        HStack {
                            Text("Check \(viewModel.email) for a verification code.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Change") {
                                viewModel.changeEmail()
                            }
                            .font(.subheadline)
                        }
                        .padding(.horizontal)
                        .opacity(viewModel.showOtpField ? 1 : 0)
                        .disabled(!viewModel.showOtpField)
                        
                        
                        if viewModel.showOtpField {
                            TextField("6-Digit OTP", text: $viewModel.otp)
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .multilineTextAlignment(.center)
                                .tracking(10)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(isOtpFocused ? Color.accentColor : Color.gray.opacity(0.5),
                                                lineWidth: isOtpFocused ? 2 : 1)
                                )
                                .padding(.horizontal)
                                .focused($isOtpFocused)
                                .id("otpField")
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        isOtpFocused = true
                                    }
                                }
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                        
                        if viewModel.showOtpField && viewModel.canResendOTP {
                            // Updated to match LoadingButton parameters
                            LoadingButton(
                                action: { viewModel.resendOtp() },
                                isLoading: viewModel.isResendingOTP,
                                isDisabled: false,
                                isPrimary: false,
                                tint: .accentColor,
                                animationName: "FastLoading"
                            ) {
                                Text("Resend code")
                                    .font(.subheadline)
                            }
                            .padding(.top, 5)
                        }
                        
                        
                        // Enhanced button with loading state - updated to match LoadingButton parameters
                        LoadingButton(
                            action: {
                                if viewModel.showOtpField {
                                    viewModel.verifyOtpButtonTapped()
                                } else {
                                    viewModel.signUpButtonTapped()
                                }
                            },
                            isLoading: viewModel.showOtpField ? viewModel.isVerifyingOTP : viewModel.isSignUpLoading,
                            isDisabled: viewModel.showOtpField ? viewModel.isVerifyOtpButtonDisabled : viewModel.isSignUpButtonDisabled,
                            isPrimary: true,
                            tint: .accentColor,
                            animationName: "FastLoading"
                        ) {
                            HStack {
                                Spacer()
                                Text(viewModel.showOtpField ? "Submit" : "Sign Up")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .padding(.top, (viewModel.showOtpField && viewModel.canResendOTP) ? 0 : -35)
                        .padding(.horizontal)
                        .id("submitButton") // Add an ID for scrolling
                        .id(viewModel.showOtpField) // Change ID to help SwiftUI animations
                        
                        HStack {
                            Text("Already have an account?")
                                .foregroundColor(.secondary)
                            Button("Log In") {
                                dismiss()
                            }
                            .fontWeight(.semibold)
                            .tint(.accentColor)
                            
                        }
                        .opacity(viewModel.showOtpField ? 0 : 1) // Hide when OTP field shows
//                        .padding(.bottom, 15)
                        
                    }
                    .padding()
                    
                    //                    .padding(.bottom, 8) // Add consistent padding at the bottom
                }
                .onChange(of: isKeyboardVisible) { visible in
                    if visible {
                        withAnimation {
                            scrollProxy.scrollTo("submitButton", anchor: .bottom)
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    // This creates space at the bottom when keyboard is visible
                    if isKeyboardVisible {
                        Color.clear.frame(height: keyboardHeight)
                    }
                }
            }
           
            Spacer()
            
            HawcxFooterView()
                .padding(.bottom, 10)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .disabled(viewModel.isSignUpLoading || viewModel.isVerifyingOTP || viewModel.isResendingOTP)
        .padding(.horizontal, 15)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .animation(.easeInOut, value: viewModel.showOtpField) // Animate changes based on showOtpField
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            viewModel.appViewModel = appViewModel
            
            viewModel.showOtpField = false
            viewModel.otp = ""
            viewModel.canResendOTP = false
            
            if let prefillEmail = viewModel.prefilledEmail, !prefillEmail.isEmpty {
                viewModel.email = prefillEmail
            }
            
            viewModel.onUserAlreadyExists = { email in
                // Simply dismiss this view to return to login
                dismiss()
            }
            
            // Set up the automatic login callback using the shared auth manager
            viewModel.onSuccessfulSignUpCompleted = { email in
                // Show non-dismissible loading alert
                appViewModel.showLoadingAlert(title: "Success", message: "Account created successfully! Logging you in...")
                
                // Immediately dismiss SignUpView to return to LoginView where biometric prompt can be shown
                Task { @MainActor in
                    // Small delay to ensure alert is visible before dismissing
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
                    
                    // Dismiss SignUpView to return to LoginView
                    dismiss()
                    
                    // After dismissing, initiate auto-login which will run in LoginViewModel
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                        
                        // Start automatic login process
                        sharedAuthManager.loginWithEmail(email) { success in
                            if !success {
                                // Only show error alert if login fails
                                Task { @MainActor in
                                    appViewModel.showAlert(title: "Login Error",
                                        message: "Registration was successful, but we couldn't log you in automatically. Please try logging in manually.")
                                }
                            }
                            // If successful, the LoginViewModel will handle showing biometric prompt
                        }
                    }
                }
            }
            
            if !viewModel.showOtpField {
                isEmailFieldFocused = true
            }
            
            // Set up keyboard notifications
            setupKeyboardNotifications()
        }
        .onDisappear {
            // Clean up keyboard notifications
            removeKeyboardNotifications()
        }
        .blur(radius: (appViewModel.alertInfo != nil) ? 6 : 0)
        .allowsHitTesting(!(appViewModel.alertInfo != nil))
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .padding(6)
                }
                .disabled(viewModel.isSignUpLoading || viewModel.isVerifyingOTP || viewModel.isResendingOTP)
            }
        }
    }
    
    // Set up keyboard notification observers
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            keyboardHeight = keyboardFrame.height
            isKeyboardVisible = true
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            keyboardHeight = 0
            isKeyboardVisible = false
        }
    }
    
    // Remove notification observers when view disappears
    private func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
}

//struct SignUpView_Previews: PreviewProvider {
//    static var previews: some View {
//        let previewAppViewModel = AppViewModel()
//        
//        SignUpView(appViewModel: previewAppViewModel)
//            .environmentObject(previewAppViewModel)
//    }
//}
