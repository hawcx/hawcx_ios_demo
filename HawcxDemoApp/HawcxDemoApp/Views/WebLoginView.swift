//
//  WebLoginView.swift
//  HawcxDemoApp
//
//  Updated on 4/15/25.
//

import SwiftUI
import HawcxFramework

struct WebLoginView: View {
    @StateObject private var viewModel: WebLoginViewModel
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isPinFocused: Bool
    @State private var showQRScanner = false
    
    init(appViewModel: AppViewModel) {
        _viewModel = StateObject(wrappedValue: WebLoginViewModel(appViewModel: appViewModel))
    }
    
    var body: some View {
        ZStack {
            // Netflix-style dark background
            ChikflixTheme.background.edgesIgnoringSafeArea(.all)
            
            VStack {
                ScrollView {
                    // Main content for option selection or manual entry
                    if !viewModel.showApprovalScreen {
                        VStack(spacing: 20) {
                            Spacer(minLength: 30)
                            
                            // Chikflix Logo
                            Text("CHIKFLIX")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(ChikflixTheme.primary)
                                .padding(.top, 20)
                                .padding(.bottom, 30)
                            
                            // PIN entry or Option buttons based on state
                            if viewModel.showManualEntry {
                                manualEntryView
                            } else {
                                // Header for option selection view
                                VStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(ChikflixTheme.primary.opacity(0.2))
                                            .frame(width: 80, height: 80)
                                        
                                        Image(systemName: "qrcode")
                                            .font(.system(size: 40))
                                            .foregroundColor(ChikflixTheme.primary)
                                    }
                                    
                                    Text("Connect Your Browser")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(ChikflixTheme.textPrimary)
                                    
                                    Text("Sign in to Chikflix on your web browser without typing your password")
                                        .font(.subheadline)
                                        .foregroundColor(ChikflixTheme.textSecondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                }
                                .padding(.bottom, 30)
                                
                                optionButtonsView
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 15)
                    } else {
                        // Show approval screen when applicable
                        WebLoginApprovalView(
                            viewModel: viewModel,
                            sessionDetails: viewModel.sessionDetails,
                            onApprove: { viewModel.approveWebLogin() },
                            onDeny: { viewModel.denyWebLogin() }
                        )
                    }
                }
                
                Spacer()
                
                // Netflix-styled footer with Hawcx attribution
                ChikflixFooterView()
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .animation(.easeInOut, value: viewModel.showManualEntry)
        .animation(.easeInOut, value: viewModel.showApprovalScreen)
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            viewModel.appViewModel = appViewModel
            
            viewModel.onSuccessCallback = {
                dismiss()
            }
            
            viewModel.onShowQRScanner = {
                showQRScanner = true
            }
            
            if !viewModel.showManualEntry && !viewModel.showApprovalScreen {
                viewModel.pin = ""
            }
        }
        .blur(radius: (appViewModel.alertInfo != nil) ? 6 : 0)
        .allowsHitTesting(!(appViewModel.alertInfo != nil))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if viewModel.showApprovalScreen {
                        withAnimation {
                            viewModel.showApprovalScreen = false
                            viewModel.sessionDetails = nil
                            viewModel.pin = ""
                        }
                    } else if viewModel.showManualEntry {
                        withAnimation { viewModel.showManualEntry = false }
                        viewModel.pin = ""
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(ChikflixTheme.textPrimary)
                }
                .disabled(viewModel.isLoading)
            }
            
            ToolbarItem(placement: .principal) {
                Text(viewModel.showApprovalScreen
                     ? "Approve Login"
                     : (viewModel.showManualEntry ? "Manual Entry" : "Web Login"))
                .font(.headline)
                .foregroundColor(ChikflixTheme.textPrimary)
            }
        }
        .fullScreenCover(isPresented: $showQRScanner) {
            NavigationStack { // Add NavigationStack for title/buttons
                RealQRScannerView(
                    onScanSuccess: { code in
                        viewModel.pin = code
                        // Remove this line that was causing the issue
                        // viewModel.showManualEntry = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            viewModel.submitPinButtonTapped()
                        }
                    },
                    onDismiss: { showQRScanner = false }
                )
            }
        }
    }
    
    // MARK: - Subviews
    
    private var manualEntryView: some View {
        VStack(spacing: 30) {
            // Header for manual PIN entry
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(ChikflixTheme.primary.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 36))
                        .foregroundColor(ChikflixTheme.primary)
                }
                
                Text("Enter PIN Code")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ChikflixTheme.textPrimary)
                
                Text("Enter the 7-digit PIN displayed on the web login screen")
                    .font(.subheadline)
                    .foregroundColor(ChikflixTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.bottom, 10)
            
            // PIN entry field
            VStack(spacing: 15) {
                // PIN boxes
                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { index in
                        digitBox(digit: index < viewModel.pin.count ? String(Array(viewModel.pin)[index]) : "")
                    }
                }
                .padding(.vertical, 10)
                
                // Hidden field for keyboard focus
                TextField("", text: $viewModel.pin)
                    .keyboardType(.numberPad)
                    .focused($isPinFocused)
                    .opacity(0)
                    .frame(height: 0)
                    .onChange(of: viewModel.pin) {
                        let newValue = viewModel.pin
                        
                        // Filter to numbers only, max 7 digits
                        let filtered = newValue.filter { $0.isNumber }.prefix(7)
                        if String(filtered) != newValue {
                            viewModel.pin = String(filtered)
                        }
                        
                        // Auto-submit when 7 digits are entered
                        if filtered.count == 7 {
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                if viewModel.pin.count == 7 {
                                    viewModel.submitPinButtonTapped()
                                }
                            }
                        }
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isPinFocused = true
                        }
                    }
            }
            .padding(.horizontal)
            .onTapGesture {
                isPinFocused = true
            }
            
            // Submit Button
            Button(action: {
                viewModel.submitPinButtonTapped()
            }) {
                HStack {
                    if viewModel.isPinSubmitting {
                        LottieView(animationName: "FastLoading", loopMode: .loop)
                            .frame(width: 25, height: 25)
                            .scaleEffect(1.5)
                    } else {
                        Text("Submit PIN")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 30)
            }
            .buttonStyle(ChikflixButtonStyle())
            .disabled(viewModel.isSubmitButtonDisabled)
            .opacity(viewModel.isSubmitButtonDisabled && !viewModel.isPinSubmitting ? 0.7 : 1.0)
            .padding(.horizontal)
            .padding(.top, 10)
            
            // Instructions
            instructionsView
        }
        .padding(.horizontal)
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }
    
    private var instructionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(ChikflixTheme.primary)
                
                Text("How to find the PIN")
                    .font(.headline)
                    .foregroundColor(ChikflixTheme.textPrimary)
            }
            
            instructionStep(
                number: "1",
                title: "Sign in to chikflix.com",
                description: "On your web browser, go to chikflix.com and select Sign In"
            )
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            instructionStep(
                number: "2",
                title: "Choose QR Code Login",
                description: "Select 'Sign in with QR code' on the login page"
            )
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            instructionStep(
                number: "3",
                title: "Find the PIN below the QR code",
                description: "A 7-digit PIN is displayed below the QR code on the website"
            )
        }
        .padding(20)
        .background(ChikflixTheme.secondaryBackground)
        .cornerRadius(8)
        .padding(.top, 20)
    }
    
    private func instructionStep(number: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(ChikflixTheme.primary)
                    .frame(width: 24, height: 24)
                
                Text(number)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(ChikflixTheme.textPrimary)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(ChikflixTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }
    
    private func digitBox(digit: String) -> some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 8)
                .stroke(digit.isEmpty ? Color.gray.opacity(0.3) : ChikflixTheme.primary, lineWidth: 1.5)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(digit.isEmpty ? ChikflixTheme.secondaryBackground : ChikflixTheme.primary.opacity(0.1))
                )
                .frame(width: 40, height: 56)
            
            if digit.isEmpty {
                // Empty indicator
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 12, height: 2)
            } else {
                // Display digit
                Text(digit)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(ChikflixTheme.textPrimary)
            }
        }
        .animation(.spring(response: 0.3), value: digit)
        .onTapGesture {
            isPinFocused = true
            
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
    
    private var optionButtonsView: some View {
        VStack(spacing: 15) {
            // Scan QR code button
            Button(action: {
                viewModel.scanQrButtonTapped()
            }) {
                HStack {
                    Text("Scan QR Code")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Image(systemName: "qrcode.viewfinder")
                        .font(.headline)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(ChikflixButtonStyle())
            .padding(.horizontal)
            
            // Manual entry button
            Button(action: {
                viewModel.manualButtonTapped()
                viewModel.pin = ""
            }) {
                HStack {
                    Text("Enter PIN Manually")
                        .font(.headline)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "keyboard")
                        .font(.headline)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundColor(ChikflixTheme.textPrimary)
                .background(ChikflixTheme.secondaryBackground)
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
            }
            .padding(.horizontal)
            
            // Information card
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(ChikflixTheme.primary)
                    
                    Text("How It Works")
                        .font(.headline)
                        .foregroundColor(ChikflixTheme.textPrimary)
                }
                .padding(.bottom, 5)
                
                HStack(alignment: .top, spacing: 15) {
                    Image(systemName: "qrcode")
                        .foregroundColor(ChikflixTheme.primary)
                        .frame(width: 24, height: 24)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Scan the QR Code")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(ChikflixTheme.textPrimary)
                        Text("Scan the QR code shown on the web login screen")
                            .font(.system(size: 14))
                            .foregroundColor(ChikflixTheme.textSecondary)
                    }
                }
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                HStack(alignment: .top, spacing: 15) {
                    Image(systemName: "keyboard")
                        .foregroundColor(ChikflixTheme.primary)
                        .frame(width: 24, height: 24)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Enter PIN")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(ChikflixTheme.textPrimary)
                        Text("Or manually enter the 7-digit PIN displayed below the QR code")
                            .font(.system(size: 14))
                            .foregroundColor(ChikflixTheme.textSecondary)
                    }
                }
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                HStack(alignment: .top, spacing: 15) {
                    Image(systemName: "checkmark.shield")
                        .foregroundColor(ChikflixTheme.primary)
                        .frame(width: 24, height: 24)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Verify Login")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(ChikflixTheme.textPrimary)
                        Text("Review login details before approving to ensure it's secure")
                            .font(.system(size: 14))
                            .foregroundColor(ChikflixTheme.textSecondary)
                    }
                }
            }
            .padding(20)
            .background(ChikflixTheme.secondaryBackground)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
            .padding(.top, 20)
            .padding(.horizontal)
        }
        .transition(.opacity.combined(with: .move(edge: .leading)))
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Web Login Approval View
struct WebLoginApprovalView: View {
    @ObservedObject var viewModel: WebLoginViewModel
    var sessionDetails: HawcxFramework.SessionDetails?
    var onApprove: () -> Void
    var onDeny: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Security icon
                ZStack {
                    Circle()
                        .fill(ChikflixTheme.primary.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "checkmark.shield.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50)
                        .foregroundColor(ChikflixTheme.primary)
                }
                .padding(.top, 30)
                
                Text("Verify Login Request")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ChikflixTheme.textPrimary)
                
                Text("Someone is trying to log in to your Chikflix account. Verify the details below to make sure it's you.")
                    .font(.subheadline)
                    .foregroundColor(ChikflixTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // Session details view
                sessionDetailsView
                    .padding(.top, 10)
                
                // Action buttons
                VStack(spacing: 15) {
                    // Approve Button
                    Button(action: { onApprove() }) {
                        HStack {
                            if viewModel.isApproving {
                                LottieView(animationName: "FastLoading", loopMode: .loop)
                                    .frame(width: 25, height: 25)
                                    .scaleEffect(1.5)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Approve Login")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                    }
                    .buttonStyle(ChikflixButtonStyle())
                    .disabled(viewModel.isDenying)
                    .opacity(viewModel.isDenying ? 0.7 : 1.0)
                    .padding(.horizontal)
                    
                    // Deny Button
                    Button(action: { onDeny() }) {
                        HStack {
                            if viewModel.isDenying {
                                LottieView(animationName: "FastLoading", loopMode: .loop)
                                    .frame(width: 25, height: 25)
                                    .scaleEffect(1.5)
                            } else {
                                Image(systemName: "xmark.circle.fill")
                                Text("Deny Login")
                                    .font(.headline)
                                    .fontWeight(.medium)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(ChikflixTheme.textPrimary)
                        .background(ChikflixTheme.secondaryBackground)
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .disabled(viewModel.isApproving)
                    .opacity(viewModel.isApproving ? 0.7 : 1.0)
                    .padding(.horizontal)
                }
                .padding(.top, 20)
                
                // Security notice
                Text("If you don't recognize this login attempt, deny the request immediately")
                    .font(.caption)
                    .foregroundColor(ChikflixTheme.primary)
                    .padding(.top, 10)
                
                Spacer(minLength: 30)
            }
            .padding()
        }
    }
    
    // Session details view with Netflix styling
    private var sessionDetailsView: some View {
        VStack(spacing: 15) {
            if let details = sessionDetails {
                Group {
                    detailRow(icon: deviceTypeIcon(details.derivedDeviceType), title: "Device Type", value: details.derivedDeviceType)
                    detailRow(icon: "display", title: "Operating System", value: details.derivedOsDetails)
                    detailRow(icon: "globe", title: "Browser", value: details.derivedBrowserWithVersion)
                    detailRow(icon: "mappin.and.ellipse", title: "Location", value: details.derivedLocation)
                    detailRow(icon: "network", title: "IP Address", value: details.ipDetails)
                    detailRow(icon: "building.2", title: "ISP", value: details.isp)
                    
                    if let devId = details.deviceId, !devId.isEmpty {
                        detailRow(icon: "tag", title: "Device ID", value: devId)
                    }
                }
            } else {
                Text("Session details unavailable")
                    .font(.subheadline)
                    .foregroundColor(ChikflixTheme.textSecondary)
                    .padding()
            }
        }
        .padding()
        .background(ChikflixTheme.secondaryBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    // Detail row with Netflix styling
    private func detailRow(icon: String, title: String, value: String?) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(ChikflixTheme.primary)
                .frame(width: 20, alignment: .center)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(ChikflixTheme.textSecondary)
                
                Text(value ?? "N/A")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(ChikflixTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.bottom, 5)
    }
    
    // Helper for device icon
    private func deviceTypeIcon(_ deviceType: String?) -> String {
        guard let type = deviceType?.lowercased() else { return "questionmark.diamond" }
        if type.contains("iphone") { return "iphone" }
        if type.contains("ipad") { return "ipad" }
        if type.contains("mac") || type.contains("desktop") || type.contains("windows") || type.contains("linux") { return "desktopcomputer" }
        if type.contains("watch") { return "applewatch" }
        if type.contains("tv") { return "appletv" }
        return "questionmark.diamond"
    }
}
