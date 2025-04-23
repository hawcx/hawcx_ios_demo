import SwiftUI

/// A dedicated modifier for non-dismissible loading alerts
struct LoadingAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isPresented) // Disable background content when alert is shown
            
            if isPresented {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                    .onTapGesture {
                        // No action - alert cannot be dismissed by tapping
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
                    
                    // Loading indicator instead of dismiss button
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.2)
                        .padding(.top, 8)
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
    /// Presents a non-dismissible loading alert
    func loadingAlert(isPresented: Binding<Bool>, title: String, message: String) -> some View {
        self.modifier(LoadingAlertModifier(isPresented: isPresented, title: title, message: message))
    }
}
