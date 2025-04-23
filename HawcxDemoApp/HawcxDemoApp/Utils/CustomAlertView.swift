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
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                    .onTapGesture {
                    }

                VStack(spacing: 15) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button(dismissButtonTitle) {
                        withAnimation {
                            isPresented = false
                        }
                    }
                    .buttonStyle(.borderedProminent) // Use a prominent style for the dismiss button
                    .tint(.accentColor) // Use the app's accent color
                }
                .padding()
                .frame(maxWidth: 300) // Limit alert width
                .background(Material.regular) // Use a blurred background material
                .cornerRadius(15)
                .shadow(radius: 10)
                .transition(.scale.combined(with: .opacity)) // Add scale and opacity animation
                .zIndex(1) // Ensure alert is on top
            }
        }
        .animation(.spring(), value: isPresented) // Animate the appearance/disappearance
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
