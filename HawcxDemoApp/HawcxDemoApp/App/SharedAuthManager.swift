//
//  SharedAuthManager.swift
//  HawcxDemoApp
//
//  Created by Agam Bhullar on 4/22/25.
//

import SwiftUI
import Combine

/// Central authentication manager that can be shared across the app
class SharedAuthManager: ObservableObject {
    // Reference to the LoginViewModel that handles authentication operations
    private var loginViewModel: LoginViewModel?
    
    // Method to register the LoginViewModel
    func registerLoginViewModel(_ viewModel: LoginViewModel) {
        self.loginViewModel = viewModel
    }
    
    // Method to perform automatic login with email and completion handler
    @MainActor func loginWithEmail(_ email: String, completion: ((Bool) -> Void)? = nil) {
        guard let loginViewModel = loginViewModel else {
            completion?(false)
            return
        }
        
        // Create a flag to ensure completion is only called once
        var completionCalled = false
        var loginCancellable: AnyCancellable?
        var timeoutTask: Task<Void, Error>?
        
        // Helper function to ensure completion is only called once and cleanup resources
        func safeCompletion(_ success: Bool) {
            guard !completionCalled else { return }
            completionCalled = true
            
            // Cancel the timeout task if it exists
            timeoutTask?.cancel()
            
            // Cancel the notification subscription
            loginCancellable?.cancel()
            
            completion?(success)
        }
        
        // Register for login result notification
        loginCancellable = NotificationCenter.default.publisher(
            for: Notification.Name("AuthLoginResult")
        )
        .receive(on: RunLoop.main)
        .sink { notification in
            if let success = notification.userInfo?["success"] as? Bool {
                safeCompletion(success)
            } else {
                safeCompletion(false)
            }
        }
        
        // Set timeout task
        timeoutTask = Task {
            do {
                // Wait for 10 seconds before timing out
                try await Task.sleep(nanoseconds: 10_000_000_000)
                safeCompletion(false)
            } catch {
                // Task was cancelled, we can ignore this
            }
        }
        
        // Start login process - specify that this is an automatic login
        loginViewModel.loginWithEmail(email, isAutomatic: true)
    }
}
