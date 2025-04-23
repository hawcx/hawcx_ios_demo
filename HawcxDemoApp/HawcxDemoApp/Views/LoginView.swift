//
//  LoginView.swift
//  HawcxDemoApp
//
//  Updated 4/16/25
//

import SwiftUI
import LocalAuthentication
import HawcxFramework // Ensure SDK is imported

struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel
    @EnvironmentObject var appViewModel: AppViewModel // Use shared AppViewModel
    @EnvironmentObject var sharedAuthManager: SharedAuthManager
    
    // Navigation States
    @State private var navigateToSignUp = false
    // Home navigation is now controlled by AppViewModel.authenticationState
    // @State private var navigateToHome = false // Removed
    
    @FocusState private var isEmailFieldFocused: Bool
    @State private var showBiometricAnimation = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var isKeyboardVisible = false
    
    init(appViewModel: AppViewModel) {
        // Use the AppViewModel passed down
        _viewModel = StateObject(wrappedValue: LoginViewModel(appViewModel: appViewModel))
    }
    
    var body: some View {
        ZStack {
            // --- Main login content ---
            VStack {
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(spacing: 20) {
                            // Logo, Title, Email Field, Login Button, Sign Up Prompt, Biometric Button
                            Image("Hawcx_Logo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 200)
                                .clipped()
                                .overlay (
                                    Text("HAWCX")
                                        .font(.system(size: 60, weight: .medium, design: .serif))
                                        .padding(.top, 150))
                            
                            Text("Log in to continue")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.top, 50)
                            
                            TextField("Email Address", text: $viewModel.email)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10).stroke(isEmailFieldFocused ? Color.blue : Color.gray.opacity(0.5), lineWidth: isEmailFieldFocused ? 2 : 1)
                                )
                                .focused($isEmailFieldFocused)
                                .padding(.horizontal)
                            
                            LoadingButton(action: {
                                viewModel.loginButtonTapped()
                            },
                                          isLoading: viewModel.isLoggingIn,
                                          isDisabled: viewModel.isLoginButtonDisabled)
                            {
                                HStack {
                                    Spacer();
                                    Text("Log In")
                                        .fontWeight(.semibold);
                                    Spacer()
                                }
                            }
                            .padding(.horizontal).padding(.bottom).id("LoginButton")
                            
                            HStack {
                                Text("Don't have an account?")
                                    .foregroundColor(.secondary)
                                Button("Sign Up") { navigateToSignUp = true }
                                    .fontWeight(.semibold)
                                    .tint(.accentColor)
                            }
                            
                            // Biometric Button (Conditional)
                            if viewModel.showBiometricButton {
                                Button { /* Biometric action */ viewModel.biometricButtonTapped() } label: { biometricButtonLabel }
                                    .buttonStyle(.plain)
                                    .disabled(!viewModel.isBiometricAvailable || viewModel.isBiometricLoggingIn)
                                    .opacity(viewModel.isBiometricAvailable ? 1.0 : 0.5)
                                    .padding(.horizontal).padding(.top, 8)
                            }
                        }
                        .padding()
                    }
                    // Keyboard adaptive scrolling
                    .onChange(of: isKeyboardVisible) { visible in
                        if visible {
                            withAnimation {
                                scrollProxy.scrollTo("LoginButton", anchor: .bottom)
                            }
                        }
                    }
                    .safeAreaInset(edge: .bottom) {
                        if isKeyboardVisible {
                            Color.clear.frame(height: keyboardHeight)
                        }
                    }
                }
                //                .ignoresSafeArea(.keyboard, edges: .bottom)
                
                Spacer() // Pushes content up
                
                HawcxFooterView()
                    .padding(.bottom, 10)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .disabled(viewModel.isLoggingIn || viewModel.isBiometricLoggingIn) // Disable during actions
            .padding(.horizontal, 15)
            .onTapGesture { hideKeyboard() } // Dismiss keyboard on tap
            // Blur background when alerts or prompts are shown
            .blur(radius: (appViewModel.alertInfo != nil) || viewModel.shouldShowBiometricEnablePrompt ? 6 : 0)
            .allowsHitTesting(!(appViewModel.alertInfo != nil || viewModel.shouldShowBiometricEnablePrompt))
            
            // --- Overlays ---
            
            // Biometric enable prompt (if shown)
            if viewModel.shouldShowBiometricEnablePrompt {
                biometricEnablePromptView
                    .zIndex(1) // Ensure it's above blurred content
            }
            
            // MARK: REMOVED Add Device Confirmation Alert/Dialog (Navigation handles it)
            
        }
        // --- View Modifiers ---
        .animation(.easeInOut, value: viewModel.shouldShowBiometricEnablePrompt)
        .onAppear(perform: setupView)
        .onDisappear(perform: removeKeyboardNotifications)
//        .navigationTitle("Login") // Simplified title
//        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true) // Hide default back button
        
        // --- Navigation Destinations ---
        .navigationDestination(isPresented: $navigateToSignUp) {
            let signUpVM = SignUpViewModel(appViewModel: appViewModel)
            if !viewModel.email.isEmpty {
                signUpVM.prefilledEmail = viewModel.email
                signUpVM.email = viewModel.email
            }
            return SignUpView(viewModel: signUpVM, appViewModel: appViewModel)
        }
        // MARK: Corrected Navigation Destination for Add Device
        .navigationDestination(isPresented: $viewModel.navigateToAddDeviceView) {
            // Pass the email AND the LoginViewModel instance (as AddDeviceCallback)
            if let email = viewModel.emailForAddDevice {
                // MARK: Changed View to AddDeviceFlowView
                AddDeviceView(emailToAdd: email, appViewModel: appViewModel)
            } else {
                Text("Error: Missing user information.")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var biometricButtonLabel: some View {
        HStack {
            Image(systemName: biometricType() == .faceID ? "faceid" : "touchid")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
            if viewModel.isBiometricLoggingIn {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity, alignment: .center)
                
                //                LottieView(animationName: "FastLoading", loopMode: .loop)
                //                    .frame(width: 25, height: 25)
                //                    .frame(maxWidth: .infinity, alignment: .center).scaleEffect(2)
            } else {
                Text("Login with Biometrics")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            Spacer()
            if !viewModel.isBiometricLoggingIn {
                Image(systemName: "arrow.right.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(LinearGradient(
            gradient: Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)]),
            startPoint: .topLeading, endPoint: .bottomTrailing))
        .cornerRadius(12)
        .shadow(color: Color.accentColor.opacity(0.4), radius: showBiometricAnimation ? 2 : 4, x: 0, y: showBiometricAnimation ? 1 : 2)
        .scaleEffect(showBiometricAnimation ? 0.97 : 1.0)
    }
    
    private var biometricEnablePromptView: some View {
        Group {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .transition(.opacity)
            
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: biometricType() == .faceID ? "faceid" : "touchid")
                        .font(.system(size: 30))
                        .foregroundColor(.accentColor)
                    Text("Enable Biometric Login")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Text("Use \(biometricType() == .faceID ? "Face ID" : "Touch ID") for faster login?")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack(spacing: 15) {
                    Button("Not Now") {
                        viewModel.declineBiometrics()
                    }
                    .secondaryButtonStyle()
                    .frame(minWidth: 120)
                    
                    Button("Enable") {
                        viewModel.enableBiometrics()
                    }
                    .primaryButtonStyle()
                    .frame(minWidth: 120)
                }
                .padding(.top, 10)
            }
            .padding(24)
            .background(Material.regular)
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding(30)
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    // MARK: - Helper Functions
    
    private func setupView() {
        viewModel.appViewModel = appViewModel
        viewModel.checkBiometricAvailability()
        sharedAuthManager.registerLoginViewModel(viewModel)
        viewModel.loadInitialEmail()
        viewModel.attemptAutomaticBiometricLogin()
        isEmailFieldFocused = true // Auto-focus email
        
        // Setup Navigation Callbacks
        viewModel.onSignUpRequested = {
            navigateToSignUp = true
        }
        viewModel.onLoginSuccess = { username in
            // Let AppViewModel handle state change which controls ContentView's navigation
            appViewModel.userDidLogin(username: username)
        }
        // No onResetDeviceRequested needed
        
        setupKeyboardNotifications()
    }
    
    private func biometricType() -> LABiometryType {
        let context = LAContext(); _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil); return context.biometryType
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
    private func hideKeyboard() { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
    
}

// MARK: - Previews
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { // Add NavigationStack for preview context
            LoginView(appViewModel: AppViewModel()) // Use a dummy AppViewModel
        }
    }
}
