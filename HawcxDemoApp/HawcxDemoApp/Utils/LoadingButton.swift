//
//  LoadingButton.swift
//  HawcxDemoApp
//
//  Created by Agam Bhullar on 4/15/25.
//

import SwiftUI
import Lottie

struct LoadingButton<Label: View>: View {
    var action: () -> Void
    var isLoading: Bool
    var isDisabled: Bool
    var isPrimary: Bool = true // To differentiate between primary and secondary buttons
    var tint: Color = .accentColor
    var animationName: String = "loading_spinner" // Your Lottie animation JSON filename (without extension)
    @ViewBuilder var label: () -> Label
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Show Lottie animation when loading
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
            .background(isPrimary ? tint : Color.clear)
            .foregroundColor(isPrimary ? .white : tint)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isPrimary ? Color.clear : tint, lineWidth: isPrimary ? 0 : 1)
            )
        }
        .disabled(isDisabled || isLoading)
        .opacity((isDisabled && !isLoading) ? 0.6 : 1.0)
    }
}

// Lottie View Wrapper
struct LottieView: UIViewRepresentable {
    var animationName: String
    var loopMode: LottieLoopMode = .loop
    
    let animationView = LottieAnimationView()  // Make sure this is correct
    
    func makeUIView(context: UIViewRepresentableContext<LottieView>) -> UIView {
        let view = UIView(frame: .zero)
        
        // Ensure the animation file name is correct
        let animation = LottieAnimation.named(animationName)
        animationView.animation = animation
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = loopMode
        animationView.play()
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<LottieView>) {
        // No need to update anything
    }
}


// For backward compatibility and preview (fallback if Lottie isn't available)
struct LoadingSpinner: View {
    @State private var isAnimating = false
    var color: Color = .white
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(color, lineWidth: 2)
            .frame(width: 20, height: 20)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .onAppear {
                withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                    self.isAnimating = true
                }
            }
    }
}
