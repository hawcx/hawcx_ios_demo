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
                // Dark overlay - darker for Netflix style
                Color.black.opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                    .onTapGesture {
                        // No action - alert cannot be dismissed by tapping
                    }
                
                VStack(spacing: 20) {
                    // Title - bolder with Netflix-style
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    // Message - light gray with Netflix-style
                    Text(message)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color.gray.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                    
                    // Netflix-style spinner with red color
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: ChikflixTheme.primary))
                        .scaleEffect(1.0)
                        .padding(.vertical, 5)
                }
                .padding(.vertical, 25)
                .padding(.horizontal, 25)
                .frame(width: 300) // Fixed width for consistency with regular alert
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
    /// Presents a non-dismissible loading alert
    func loadingAlert(isPresented: Binding<Bool>, title: String, message: String) -> some View {
        self.modifier(LoadingAlertModifier(isPresented: isPresented, title: title, message: message))
    }
}
