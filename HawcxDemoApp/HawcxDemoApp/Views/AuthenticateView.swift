//
//  AuthenticateView.swift
//  HawcxDemoApp
//
//  Created for V4 SDK Integration.
//
import SwiftUI
import LocalAuthentication
import HawcxFramework

struct AuthenticateView: View {
    @StateObject private var viewModel: AuthenticateViewModel
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var sharedAuthManager: SharedAuthManager // For automatic login
    
    @Environment(\.dismiss) private var dismiss

    // FocusState for OTP field needs to be in the View
    @FocusState private var isEmailFieldFocusedLocal: Bool
    @FocusState private var isOtpFieldFocusedLocal: Bool
    @State private var showBiometricAnimation = false // For button tap effect

    @State private var keyboardHeight: CGFloat = 0
    @State private var isKeyboardVisible = false
    
    private static var hasAttemptedAutomaticLogin = false


    init(appViewModel: AppViewModel) {
        _viewModel = StateObject(wrappedValue: AuthenticateViewModel(appViewModel: appViewModel))
    }
    
    // Preview Initializer
    init(viewModel: AuthenticateViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            ChikflixTheme.background.edgesIgnoringSafeArea(.all)

            VStack {
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(spacing: 25) {
                            Image("Logo")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: 300, minHeight: 150, maxHeight: 150)
                                .clipped()

//                            Text(viewModel.isOtpVisible ? "Verify Your Email" : "Sign In or Create Account")
//                                .font(.system(size: 26, weight: .bold))
//                                .foregroundColor(ChikflixTheme.textPrimary)
//                                .padding(.horizontal, 20)
                            
                            Text(viewModel.isOtpVisible ? "Enter the 6-digit code sent to \(viewModel.email)." : "Enter your email to continue.")
                                .font(.title3).bold()
                                .foregroundColor(ChikflixTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 10)

                            emailField

                            if viewModel.isOtpVisible {
                                otpField
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                            
                            actionButton.id("ActionButton")

                            if !viewModel.email.isEmpty && !isValidEmail(viewModel.email) && !viewModel.isOtpVisible {
                                Text("Please enter a valid email address.")
                                    .font(.caption)
                                    .foregroundColor(ChikflixTheme.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 20)
                            }

                            if viewModel.showBiometricButton && !viewModel.isOtpVisible {
                                biometricAuthButton
                                    .padding(.top, 10)
                            }
                            
                            Spacer(minLength: 50)
                        }
                        .padding(.bottom, 20)
                    }
                    .onChange(of: isKeyboardVisible) { notVisible, visible in
                         if visible {
                             withAnimation {
                                 scrollProxy.scrollTo("ActionButton", anchor: .bottom)
                             }
                         }
                     }
                    .safeAreaInset(edge: .bottom) {
                         if isKeyboardVisible {
                             Color.clear.frame(height: keyboardHeight)
                         }
                     }
                }
                Spacer()
                ChikflixFooterView()
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .disabled(viewModel.isLoading || viewModel.isBiometricLoggingIn || viewModel.shouldShowBiometricEnablePrompt)
            .onTapGesture { appViewModel.hideKeyboard() }
            .blur(radius: (appViewModel.alertInfo != nil || appViewModel.loadingAlertInfo != nil || viewModel.shouldShowBiometricEnablePrompt) ? 6 : 0)
            .allowsHitTesting(!(appViewModel.alertInfo != nil || appViewModel.loadingAlertInfo != nil || viewModel.shouldShowBiometricEnablePrompt))

            if viewModel.shouldShowBiometricEnablePrompt {
                biometricEnablePromptView
                    .zIndex(1) // Ensure prompt is on top
            }
        }
        .animation(.easeInOut, value: viewModel.isOtpVisible)
        .animation(.easeInOut, value: viewModel.shouldShowBiometricEnablePrompt)
        .onAppear(perform: setupView)
        .onDisappear(perform: removeKeyboardNotifications)
        .navigationBarBackButtonHidden(true)
//        .navigationTitle(viewModel.isOtpVisible ? "Verify Code" : "Authenticate")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if viewModel.isOtpVisible {
                        viewModel.changeEmail() // Go back to email entry
                    } else {
                        dismiss() // Dismiss the AuthenticateView itself
                    }
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(ChikflixTheme.textPrimary)
                        .padding(6)
                }
                .disabled(viewModel.isLoading || viewModel.isBiometricLoggingIn)
            }
        }
        // Synchronize local FocusState with ViewModel's FocusState request
        .onChange(of: viewModel.isOtpFieldFocused) { oldFocusValue, newFocusValue in
            isOtpFieldFocusedLocal = newFocusValue
        }
        .onChange(of: isOtpFieldFocusedLocal) { oldFocusValue, newFocusValue in
            if viewModel.isOtpFieldFocused != newFocusValue {
                viewModel.isOtpFieldFocused = newFocusValue
            }
        }
        .onChange(of: viewModel.isEmailFieldFocused) { oldValue, newValue in
            isEmailFieldFocusedLocal = newValue
        }
        .onChange(of: isEmailFieldFocusedLocal) { oldValue, newValue in
            if viewModel.isEmailFieldFocused != newValue {
                viewModel.isEmailFieldFocused = newValue
            }
        }
    }

    // MARK: - Subviews
    private var emailField: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Email")
                .font(.caption)
                .foregroundColor(ChikflixTheme.textSecondary)
                .padding(.horizontal, 20)
            
            TextField("Enter email address", text: $viewModel.email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .accentColor(Color.white)
                .autocapitalization(.none)
                .padding()
                .background(ChikflixTheme.inputBackground)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10).stroke(viewModel.isEmailFieldFocused ? Color.red : Color.gray.opacity(0.5), lineWidth: viewModel.isEmailFieldFocused ? 2 : 1)
                )
                .focused($isEmailFieldFocusedLocal)
                .padding(.horizontal)
                .disabled(viewModel.isOtpVisible || viewModel.isLoading || viewModel.isBiometricLoggingIn)
                .opacity((viewModel.isOtpVisible && !viewModel.isLoading) ? 0.7 : 1.0)
        }
    }

    private var otpField: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("Verification Code")
                    .font(.caption)
                    .foregroundColor(ChikflixTheme.textSecondary)
                Spacer()
                Button("Change Email") {
                    viewModel.changeEmail()
                }
                .font(.caption)
                .foregroundColor(ChikflixTheme.primary)
            }
            .padding(.horizontal, 20)

            TextField("6-Digit OTP", text: $viewModel.otp)
                .keyboardType(.numberPad)
                .accentColor(Color.white)
                .textContentType(.oneTimeCode)
                .font(.system(size: 16, weight: .medium, design: .monospaced)) // Adjusted size
                .multilineTextAlignment(.center)
                .tracking(10) // Letter spacing for OTP
                .padding()
                .background(ChikflixTheme.inputBackground.opacity(0.9)) // Slightly different background
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10).stroke(isOtpFieldFocusedLocal ? Color.red : Color.gray.opacity(0.5), lineWidth: isOtpFieldFocusedLocal ? 2 : 1)
                )
                .focused($isOtpFieldFocusedLocal) // Use local FocusState
                .padding(.horizontal)
                .disabled(viewModel.isLoading || viewModel.isBiometricLoggingIn)
        }
    }

    private var actionButton: some View {
        Button {
            viewModel.authenticateButtonTapped()
        } label: {
            ZStack {
                if viewModel.isLoading && !viewModel.isBiometricLoggingIn { // Show Lottie only for general loading
                    LottieView(animationName: "FastLoading", loopMode: .loop)
                        .frame(width: 25, height: 25)
                        .scaleEffect(1.5)
                } else {
                    Text(viewModel.actionButtonText)
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 25) // Consistent height
        }
        .padding()
        .background(ChikflixTheme.primary)
        .foregroundColor(.white)
        .cornerRadius(8)
        .disabled(viewModel.isActionButtonDisabled || viewModel.isBiometricLoggingIn)
        .opacity((viewModel.isActionButtonDisabled || viewModel.isBiometricLoggingIn) ? 0.7 : 1.0)
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private var biometricAuthButton: some View {
        Button {
            viewModel.biometricButtonTapped()
            withAnimation(.easeInOut(duration: 0.2)) { showBiometricAnimation = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation { showBiometricAnimation = false }
            }
        } label: {
            Group {
                if viewModel.isBiometricLoggingIn {
                    // ————— Loading state: spinner centered —————
                    HStack {
                        Image(systemName: biometricType() == .faceID ? "faceid" : "touchid")
                            .font(.system(size: 20, weight: .medium))
                        
                        Spacer()
                        
                        LottieView(animationName: "FastLoading", loopMode: .loop)
                            .frame(width: 25, height: 25)
                            .scaleEffect(1.5)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right.circle")
                            .font(.system(size: 18, weight: .medium))
                            .opacity(0.9)
                    }
                } else {
                    // ————— Normal state: icon, text, spacer, chevron —————
                    HStack {
                        Image(systemName: biometricType() == .faceID ? "faceid" : "touchid")
                            .font(.system(size: 20, weight: .medium))
                        
                        Text("Sign in with \(biometricType() == .faceID ? "Face ID" : "Touch ID")")
                            .font(.headline)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right.circle")
                            .font(.system(size: 18, weight: .medium))
                            .opacity(0.9)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(ChikflixTheme.primary.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(showBiometricAnimation ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.isBiometricAvailable || viewModel.isLoading || viewModel.isBiometricLoggingIn)
        .opacity((!viewModel.isBiometricAvailable || viewModel.isLoading || viewModel.isBiometricLoggingIn) ? 0.5 : 1.0)
        .padding(.horizontal, 20)
    }

    
    private var biometricEnablePromptView: some View {
        Group {
            Color.black.opacity(0.85) // Darker overlay
                .edgesIgnoringSafeArea(.all)
                .transition(.opacity)
            
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: biometricType() == .faceID ? "faceid" : "touchid")
                        .font(.system(size: 30))
                        .foregroundColor(ChikflixTheme.primary)
                    Text("Enable Biometric Login")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ChikflixTheme.textPrimary)
                }
                .padding(.top, 5)
                
                Text("Use \(biometricType() == .faceID ? "Face ID" : "Touch ID") for faster authentication?")
                    .font(.body)
                    .foregroundColor(ChikflixTheme.textPrimary.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack(spacing: 15) {
                    Button("Not Now") {
                        viewModel.declineBiometrics()
                    }
                    .foregroundColor(ChikflixTheme.textPrimary)
                    .padding()
                    .frame(minWidth: 120)
                    .background(ChikflixTheme.inputBackground) // Darker gray
                    .cornerRadius(6)
                    
                    Button("Enable") {
                        viewModel.enableBiometrics()
                    }
                    .foregroundColor(ChikflixTheme.textPrimary)
                    .padding()
                    .frame(minWidth: 120)
                    .background(ChikflixTheme.primary)
                    .cornerRadius(6)
                }
                .padding(.top, 10)
                .padding(.bottom, 5)
            }
            .padding(24)
            .background(ChikflixTheme.secondaryBackground) // Slightly lighter dark
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.5), radius: 15, x: 0, y: 8)
            .padding(30)
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Helper Functions
    private func setupView() {
        viewModel.appViewModel = appViewModel
        sharedAuthManager.registerAuthenticateViewModel(viewModel) // Register with SharedAuthManager
        viewModel.loadInitialEmail()
        viewModel.checkBiometricAvailability()

        if !AuthenticateView.hasAttemptedAutomaticLogin {
            print("[AuthenticateView] First automatic biometric login attempt for V4.")
            AuthenticateView.hasAttemptedAutomaticLogin = true
            viewModel.attemptAutomaticBiometricLogin()
        } else {
            print("[AuthenticateView] Skipping automatic biometric login for V4 - already attempted this session.")
        }
        
        if !viewModel.isOtpVisible { // Only focus email if OTP is not visible
            viewModel.isEmailFieldFocused = true
        }

        // Setup callback for when authentication is successful
        viewModel.onSuccessfullyAuthenticatedAndLoggedIn = { username in
            appViewModel.userDidLogin(username: username)
        }
        
        setupKeyboardNotifications()
    }

    private func biometricType() -> LABiometryType {
        let context = LAContext(); _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil); return context.biometryType
    }
    
    // Keyboard notification handling
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

    private func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

// MARK: - Preview
struct AuthenticateView_Previews: PreviewProvider {
    static var previews: some View {
        let appVM = AppViewModel()
        let authVM = AuthenticateViewModel(appViewModel: appVM)
        
        // Scenario 1: Default email entry
        let previewAuthVMDefault = AuthenticateViewModel.createPreviewModel(appViewModel: appVM)
        
        // Scenario 2: OTP Visible
        let previewAuthVMOtp = AuthenticateViewModel.createPreviewModel(appViewModel: appVM, email: "user@example.com", isOtpVisible: true)
        
        // Scenario 3: Biometric Button Visible
        let previewAuthVMBiometric = AuthenticateViewModel.createPreviewModel(appViewModel: appVM, email: "bio@example.com", showBiometricButton: true, isBiometricAvailable: true)
        
        // Scenario 4: Biometric Prompt Visible
        let previewAuthVMBioPrompt = AuthenticateViewModel.createPreviewModel(appViewModel: appVM, email: "prompt@example.com", shouldShowBiometricEnablePrompt: true)

        return Group {
            NavigationStack {
                AuthenticateView(viewModel: previewAuthVMDefault)
                    .environmentObject(appVM)
                    .environmentObject(SharedAuthManager())
            }
            .previewDisplayName("Default Email Entry")

            NavigationStack {
                AuthenticateView(viewModel: previewAuthVMOtp)
                    .environmentObject(appVM)
                    .environmentObject(SharedAuthManager())
            }
            .previewDisplayName("OTP Visible")
            
            NavigationStack {
                AuthenticateView(viewModel: previewAuthVMBiometric)
                    .environmentObject(appVM)
                    .environmentObject(SharedAuthManager())
            }
            .previewDisplayName("Biometric Button Visible")

            NavigationStack {
                AuthenticateView(viewModel: previewAuthVMBioPrompt)
                    .environmentObject(appVM)
                    .environmentObject(SharedAuthManager())
            }
            .previewDisplayName("Biometric Enable Prompt")
        }
    }
}

extension AuthenticateViewModel {
    static func createPreviewModel(appViewModel: AppViewModel,
                                   email: String = "test@example.com",
                                   otp: String = "",
                                   isOtpVisible: Bool = false,
                                   isLoading: Bool = false,
                                   isBiometricLoggingIn: Bool = false,
                                   showBiometricButton: Bool = false,
                                   isBiometricAvailable: Bool = false,
                                   shouldShowBiometricEnablePrompt: Bool = false) -> AuthenticateViewModel {
        let model = AuthenticateViewModel(appViewModel: appViewModel)
        model.email = email
        model.otp = otp
        model.isOtpVisible = isOtpVisible
        model.isLoading = isLoading
        model.isBiometricLoggingIn = isBiometricLoggingIn
        model.showBiometricButton = showBiometricButton
        model.isBiometricAvailable = isBiometricAvailable
        model.shouldShowBiometricEnablePrompt = shouldShowBiometricEnablePrompt
        return model
    }
}
