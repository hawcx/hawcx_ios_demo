//
//  SharedAuthManager.swift
//  HawcxDemoApp
//
//  Created by Agam Bhullar on 4/22/25.
//  Updated for V4 SDK with AuthenticateViewModel
//
import SwiftUI
import Combine

@MainActor
class SharedAuthManager: ObservableObject {
    // Reference to the AuthenticateViewModel that handles authentication operations
    private var authenticateViewModel: AuthenticateViewModel?

    // Method to register the AuthenticateViewModel
    func registerAuthenticateViewModel(_ viewModel: AuthenticateViewModel) {
        self.authenticateViewModel = viewModel
        print("[SharedAuthManager] AuthenticateViewModel registered")
    }

    // Method to perform automatic V4 authentication with email and completion handler
    func authenticateWithEmail(_ email: String, completion: ((Bool) -> Void)? = nil) {
        guard let authenticateViewModel = authenticateViewModel else {
            print("[SharedAuthManager] Error: Attempted to authenticate without a registered AuthenticateViewModel")
            completion?(false)
            return
        }

        print("[SharedAuthManager] Initiating automatic V4 authentication for: \(email)")

        var completionCalled = false
        var authCancellable: AnyCancellable?
        var timeoutTask: Task<Void, Error>?

        func safeCompletion(_ success: Bool) {
            guard !completionCalled else { return }
            completionCalled = true
            timeoutTask?.cancel()
            authCancellable?.cancel()
            print("[SharedAuthManager] Calling V4 auth completion handler with result: \(success)")
            completion?(success)
        }

        // Listen for the auth result notification (same name as before for compatibility if needed)
        authCancellable = NotificationCenter.default.publisher(
            for: .authLoginResult // Reusing the existing notification name
        )
        .receive(on: RunLoop.main)
        .sink { notification in
            if let success = notification.userInfo?["success"] as? Bool,
               let authedEmail = notification.userInfo?["email"] as? String,
               authedEmail == email { // Ensure notification is for this specific attempt
                print("[SharedAuthManager] V4 Auth result received for \(authedEmail): \(success ? "success" : "failure")")
                safeCompletion(success)
            } else if notification.userInfo?["success"] == nil {
                 print("[SharedAuthManager] V4 Auth result notification received without success info or for wrong email.")
                 // Don't call safeCompletion(false) here if it might be for a different user's flow.
                 // Timeout will handle if this specific flow doesn't complete.
            }
        }

        timeoutTask = Task {
            do {
                try await Task.sleep(nanoseconds: 15_000_000_000) // 15 second timeout
                print("[SharedAuthManager] V4 Auth timeout occurred for \(email)")
                safeCompletion(false)
            } catch {
                // Task cancelled
            }
        }

        // Start V4 authentication process
        authenticateViewModel.email = email // Set email on the view model
        authenticateViewModel.authenticateButtonTapped() // This will call SDK's authenticateV4
    }
}
