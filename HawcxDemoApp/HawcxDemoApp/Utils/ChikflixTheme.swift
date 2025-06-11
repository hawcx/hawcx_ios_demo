//
//  ChikflixTheme.swift
//  HawcxDemoApp
//
//  Created by Agam Bhullar on 4/30/25.
//

import SwiftUI

// Chikflix Theme with Netflix-inspired styling
struct ChikflixTheme {
    // Colors
    static let primary = Color(hex: "e51316")
    static let background = Color.black
    static let secondaryBackground = Color(hex: "1A1A1A")
    static let textPrimary = Color.white
    static let textSecondary = Color.gray
    static let inputBackground = Color(hex: "333333")
    static let inputBorder = Color(hex: "444444")
    
    // Fonts
    struct Fonts {
        static let title = Font.system(size: 32, weight: .bold)
        static let headline = Font.system(size: 18, weight: .semibold)
        static let body = Font.system(size: 16, weight: .regular)
        static let caption = Font.system(size: 14, weight: .regular)
    }
    
    // Dimensions
    struct Dimensions {
        static let buttonHeight: CGFloat = 50
        static let cornerRadius: CGFloat = 8
        static let horizontalPadding: CGFloat = 20
        static let verticalSpacing: CGFloat = 20
    }
    
    // Animation
    static let defaultAnimation = Animation.easeInOut(duration: 0.2)
}

// Helper Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Extension for Netflix-like styling for views
extension View {
    func chikflixRoundedButtonStyle(isDisabled: Bool = false) -> some View {
        self.frame(maxWidth: .infinity)
            .frame(height: ChikflixTheme.Dimensions.buttonHeight)
            .background(isDisabled ? Color.gray : ChikflixTheme.primary)
            .foregroundColor(ChikflixTheme.textPrimary)
            .cornerRadius(ChikflixTheme.Dimensions.cornerRadius)
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.7 : 1.0)
    }
    
    func chikflixSecondaryButtonStyle(isDisabled: Bool = false) -> some View {
        self.frame(maxWidth: .infinity)
            .frame(height: ChikflixTheme.Dimensions.buttonHeight)
            .background(Color.clear)
            .foregroundColor(ChikflixTheme.textPrimary)
            .cornerRadius(ChikflixTheme.Dimensions.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: ChikflixTheme.Dimensions.cornerRadius)
                    .stroke(ChikflixTheme.textPrimary, lineWidth: 1)
            )
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.7 : 1.0)
    }
    
    func chikflixInputField() -> some View {
        self.padding()
            .background(ChikflixTheme.inputBackground)
            .cornerRadius(ChikflixTheme.Dimensions.cornerRadius)
            .foregroundColor(ChikflixTheme.textPrimary)
            .overlay(RoundedRectangle(cornerRadius: ChikflixTheme.Dimensions.cornerRadius).stroke(ChikflixTheme.inputBorder, lineWidth: 1))
            .autocapitalization(.none)
    }
}

// Netflix-inspired button style
struct ChikflixButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(ChikflixTheme.primary)
            .foregroundColor(ChikflixTheme.textPrimary)
            .font(.headline)
            .cornerRadius(ChikflixTheme.Dimensions.cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// Chikflix Loading Button
struct ChikflixLoadingButton<Label: View>: View {
    var action: () -> Void
    var isLoading: Bool
    var isDisabled: Bool
    @ViewBuilder var label: () -> Label
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    LottieView(animationName: "FastLoading", loopMode: .loop)
                        .frame(width: 25, height: 25)
                        .scaleEffect(1.5)
                } else {
                    label()
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(ChikflixTheme.primary)
            .foregroundColor(.white)
            .font(.headline)
            .cornerRadius(ChikflixTheme.Dimensions.cornerRadius)
        }
        .disabled(isDisabled || isLoading)
        .opacity((isDisabled && !isLoading) ? 0.7 : 1.0)
    }
}

// Rebranded footer view
struct ChikflixFooterView: View {
    var body: some View {
        VStack(spacing: 5) {
            Divider()
                .background(Color.gray.opacity(0.5))
                .padding(.horizontal, 40)
            
            HStack(spacing: 8) {
                Text("CHIKFLIX")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(ChikflixTheme.primary)
                
                Text("•")
                    .foregroundColor(.gray)
                
                Text("Powered by Hawcx©")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(.bottom, 10)
    }
}

// Chikflix Input Field with Netflix styling
struct ChikflixTextField: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(ChikflixTheme.inputBackground)
            .cornerRadius(ChikflixTheme.Dimensions.cornerRadius)
            .foregroundColor(ChikflixTheme.textPrimary)
            .overlay(RoundedRectangle(cornerRadius: ChikflixTheme.Dimensions.cornerRadius).stroke(Color.gray, lineWidth: 1))
            .autocapitalization(.none)
    }
}

// Logo view for Chikflix
struct ChikflixLogo: View {
    var size: CGFloat = 120
    
    var body: some View {
        Text("CHIKFLIX")
            .font(.system(size: size * 0.25, weight: .bold))
            .foregroundColor(ChikflixTheme.primary)
            .frame(width: size)
    }
}
