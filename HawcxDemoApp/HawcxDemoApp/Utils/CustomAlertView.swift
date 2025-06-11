//
//  CustomAlertView.swift
//  HawcxDemoApp
//
//  Created by Agam Bhullar on 4/14/25.
//

import SwiftUI

struct CustomAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let dismissButtonTitle: String = "OK"

    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isPresented) // Disable background content when alert is shown

            if isPresented {
                // Dark overlay - darker than before for Netflix style
                Color.black.opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                    .onTapGesture {
                        // No action on tap - Netflix alerts don't dismiss on background tap
                    }

                VStack(spacing: 16) {
                    // Title - bolder with Netflix-style
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 5)
                        .multilineTextAlignment(.center)

                    // Message - light gray with Netflix-style
                    Text(message)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color.gray.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 5)

                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal, -20)

                    // Button - Netflix red style
                    Button(dismissButtonTitle) {
                        withAnimation {
                            isPresented = false
                        }
                    }
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(ChikflixTheme.primary) // Netflix red
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 20)
                .frame(width: 300) // Fixed width for Netflix consistency
                .background(ChikflixTheme.secondaryBackground) // Dark background
                .cornerRadius(4) // Netflix uses more subtle corners
                .shadow(color: Color.black.opacity(0.4), radius: 15, x: 0, y: 5) // More dramatic shadow
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .center))) // More subtle animation
                .zIndex(1) // Ensure alert is on top
            }
        }
        .animation(.easeOut(duration: 0.2), value: isPresented) // Netflix uses quick, subtle animations
    }
}

extension View {
    func customAlert(isPresented: Binding<Bool>, title: String, message: String) -> some View {
        self.modifier(CustomAlertModifier(isPresented: isPresented, title: title, message: message))
    }

    func customAlert<E: LocalizedError>(isPresented: Binding<Bool>, error: Binding<E?>) -> some View {
        let showAlert = Binding<Bool>(
            get: { error.wrappedValue != nil },
            set: { if !$0 { error.wrappedValue = nil } }
        )

        return self.modifier(CustomAlertModifier(
            isPresented: showAlert,
            title: error.wrappedValue?.errorDescription ?? "Error",
            message: error.wrappedValue?.localizedDescription ?? "An unknown error occurred."
        ))
    }
}
