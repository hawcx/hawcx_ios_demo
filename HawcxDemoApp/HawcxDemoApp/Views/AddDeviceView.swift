//
//  AddDeviceView.swift
//  HawcxDemoApp
//
//  Created by Agam Bhullar on 4/16/25.
//  REVISED: Aligned with refactored AddDeviceViewModel.
//

import SwiftUI
import HawcxFramework // Import SDK

struct AddDeviceView: View {
    // ViewModel owned by this View
    @StateObject private var viewModel: AddDeviceViewModel
    @EnvironmentObject var appViewModel: AppViewModel // Get shared AppViewModel
    @EnvironmentObject var sharedAuthManager: SharedAuthManager
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isOtpFocused: Bool
    
    // Keyboard handling states
    @State private var keyboardHeight: CGFloat = 0
    @State private var isKeyboardVisible = false
    
    // Initializer - Pass only required data, ViewModel created internally
    init(emailToAdd: String, appViewModel: AppViewModel) {
        // Use the passed email to create the StateObject
        _viewModel = StateObject(wrappedValue: AddDeviceViewModel(email: emailToAdd, appViewModel: appViewModel))
    }
    
    var body: some View {
        VStack {
            // Indicate initial loading while OTP is being generated
            if viewModel.isStartingFlow {
                LottieView(animationName: "FastLoading", loopMode: .loop)
                    .frame(width: 25, height: 25)
                    .scaleEffect(2.0)
            }
            
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 20) {
                        // --- Header ---
                        Image("Hawcx_Logo").resizable().aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, minHeight: 150, maxHeight: 150)
                            .clipped()
                            .overlay(Text("HAWCX").font(.system(size: 50, weight: .medium, design: .serif)).padding(.top, 120))
                            .padding(.bottom, 30)
                        
//                        Text("Add This Device")
//                            .font(.largeTitle).fontWeight(.bold)
//                            .padding(.bottom, 10)
                        
                        // Different content based on flow stage
                        if viewModel.flowStage == .initial {
                            // Initial stage with explanation and send button
                            initialStageView
                        } else if viewModel.flowStage == .sending {
                            // Loading indicator while OTP is being requested
                            ProgressView("Requesting verification code...")
                                .padding(.top, 30)
                        } else {
                            // Verification stage with OTP field and submit button
                            verificationStageView(scrollProxy: scrollProxy)
                        }
                    }
                    .padding()
                }
                .onChange(of: isKeyboardVisible) { notVisible, visible in
                    if visible, viewModel.showOtpField {
                        withAnimation {
                            scrollProxy.scrollTo("submitButton", anchor: .bottom)
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    if isKeyboardVisible { Color.clear.frame(height: keyboardHeight) }
                }
            }
            
            Spacer()
            
            HawcxFooterView()
                .padding(.bottom, 10)
            
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .disabled(viewModel.isStartingFlow || viewModel.isVerifyingOTP || viewModel.isResendingOTP)
        .padding(.horizontal, 15)
        .animation(.easeInOut, value: viewModel.flowStage)
        .animation(.easeInOut, value: viewModel.showOtpField)
        .animation(.easeInOut, value: viewModel.canResendOTP)
        .onTapGesture { hideKeyboard() }
        .onAppear {
            setupKeyboardNotifications()
            
            // Set up callback for automatic login after successful device addition
            viewModel.onSuccessfulDeviceAdd = { email in
                // Show non-dismissible loading alert
                appViewModel.showLoadingAlert(
                    title: "Device Added",
                    message: "This device was successfully added. Logging you in..."
                )
                
                // Dismiss AddDeviceView to return to LoginView and proceed with auto-login
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
                    dismiss()
                    
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                        
                        // Start automatic login process
                        sharedAuthManager.loginWithEmail(email) { success in
                            if !success {
                                Task { @MainActor in
                                    appViewModel.showAlert(
                                        title: "Login Error",
                                        message: "Device was successfully added, but we couldn't log you in automatically. Please try logging in manually."
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
        .onDisappear { removeKeyboardNotifications() }
        .blur(radius: (appViewModel.alertInfo != nil) ? 6 : 0)
        .allowsHitTesting(!(appViewModel.alertInfo != nil))
        .navigationTitle("Add Device")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss()
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .padding(6)
                }
                .tint(.primary)
                .disabled(viewModel.isStartingFlow || viewModel.isVerifyingOTP || viewModel.isResendingOTP)
            }
        }
    }
    
    // MARK: - Subviews
    
    // Initial stage with explanation and send button
    private var initialStageView: some View {
        VStack(spacing: 25) {
            // Email display
            VStack(spacing: 8) {
                Text("Device Registration")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("To add this device to your account, we'll send a verification code to your email.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            // Email card
            VStack(spacing: 5) {
                Text("Email Address:")
                    .font(.subheadline)
                    .foregroundColor(.secondary.opacity(0.8))
                
                Text(viewModel.email)
                    .font(.title3)
                    .fontWeight(.medium)
                    .padding(.horizontal)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity)
//                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: Color.secondary.opacity(0.3), radius: 5, x: 0, y: 2)
            )
            .padding(.horizontal)
            .padding(.top, 10)
            
            // Send verification code button
            LoadingButton(
                action: { viewModel.sendVerificationCode() },
                isLoading: viewModel.isStartingFlow,
                isDisabled: false
            ) {
                HStack {
                    Spacer()
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 16))
                    Text("Send Verification Code")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
        }
    }
    
    // Verification stage with OTP field and submit button
    private func verificationStageView(scrollProxy: ScrollViewProxy) -> some View {
        VStack(spacing: 20) {
            Text("Enter the verification code sent to\n\(viewModel.email)")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .transition(.opacity.combined(with: .scale))
            
            TextField("6-Digit Code", text: $viewModel.otp)
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
            
            if viewModel.canResendOTP {
                LoadingButton(
                    action: { viewModel.resendOtp() },
                    isLoading: viewModel.isResendingOTP,
                    isDisabled: viewModel.isVerifyingOTP,
                    isPrimary: false,
                    tint: .accentColor
                ) {
                    Text("Resend Code")
                }
                .padding(.top, 5)
                .transition(.opacity)
            }
            
            LoadingButton(
                action: { viewModel.verifyOtpButtonTapped() },
                isLoading: viewModel.isVerifyingOTP,
                isDisabled: viewModel.isVerifyButtonDisabled
            ) {
                HStack {
                    Spacer()
                    Text("Verify & Add Device").fontWeight(.semibold)
                    Spacer()
                }
            }
            .padding(.top, (viewModel.canResendOTP) ? 5 : 20)
            .padding(.horizontal)
            .id("submitButton")
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }
    
    // MARK: - Keyboard Handling Helpers
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
            guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            self.keyboardHeight = keyboardFrame.height
            self.isKeyboardVisible = true
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            self.keyboardHeight = 0
            self.isKeyboardVisible = false
        }
    }
    
    private func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Previews
struct AddDeviceView_Previews: PreviewProvider {
    static var previews: some View {
        let appVM = AppViewModel()
        let previewEmail = "preview@test.com"
        
        return NavigationStack {
            AddDeviceView(emailToAdd: previewEmail, appViewModel: appVM)
                .environmentObject(appVM)
        }
    }
}
