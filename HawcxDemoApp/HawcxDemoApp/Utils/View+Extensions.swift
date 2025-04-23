//
//  View+Extensions.swift
//  HawcxDemoApp
//
//  Created by Agam Bhullar on 4/14/25.
//

import SwiftUI

extension View {
    func primaryButtonStyle() -> some View {
        self.buttonStyle(.borderedProminent)
           .controlSize(.large)
           .tint(.accentColor) // Or a specific brand color
    }

    func secondaryButtonStyle() -> some View {
        self.buttonStyle(.bordered)
           .controlSize(.large)
           .tint(.secondary)
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
extension AnyTransition {
    static var fade: AnyTransition {
        .opacity.animation(.easeInOut)
    }

     static var scaleAndFade: AnyTransition {
         .scale.combined(with: .opacity).animation(.spring())
     }
}

extension Notification.Name {
    static let authLoginResult = Notification.Name("AuthLoginResult")
}
