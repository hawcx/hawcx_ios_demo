//
//  HomeViewModel.swift
//  HawcxDemoApp
//
//  Created by Agam Bhullar on 4/14/25.
//  Updated for V4 SDK Logout
//
import SwiftUI
import Combine
import HawcxFramework

@MainActor
class HomeViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var isLoading: Bool = false
    @Published var navigateToWebLogin: Bool = false
    
    weak var appViewModel: AppViewModel?
    // No need for the full HawcxFramework instance if only using KeychainManager for JWTs
    // and DevSession for device details.
    private var hawcxSDK: HawcxSDK

    init(appViewModel: AppViewModel?) {
        self.appViewModel = appViewModel
        // API Key is passed to SDK components that need it.
        // HawcxFramework facade is not strictly needed here if we directly use KeychainManager for JWTs
        // and DevSessionManager.
        self.hawcxSDK = HawcxSDK(projectApiKey: Constants.apiKey)

        if let loggedInUser = appViewModel?.loggedInUsername {
            self.username = loggedInUser
            print("[HomeViewModel] Initialized for user: \(loggedInUser)")
        } else {
            print("[HomeViewModel] Warning: Initialized without a logged-in username in AppViewModel.")
            self.username = "User"
        }
    }

    convenience init() {
        self.init(appViewModel: nil)
        self.username = "preview.user@example.com"
        self.isLoading = false
    }

    nonisolated func onSuccess() {
        print("[HomeViewModel] DevSessionCallback onSuccess received. Decoding from UserDefaults.")
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.isLoading = false
        }
    }

    nonisolated func showError() {
        print("[HomeViewModel] DevSessionCallback showError received.")
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.isLoading = false
        }
    }

    func logoutButtonTapped() {
        print("[HomeViewModel] Logout initiated for user: \(username)")

        // 1. Use the new SDK function to clear only session tokens
        if !username.isEmpty {
            // Assuming 'HawcxSDK' instance is available or re-initialized
            hawcxSDK.clearSessionTokens(forUser: username)
            UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.biometricPrefix + username)
        }
        
        // 2. Clear app's own "lastUser" for UI pre-fill if desired
        //    (The SDK's clearLastLoggedInUser() could also be called if that's the intended pre-fill source)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.lastUser)

        // Clear other app-specific UserDefaults if any
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.accessToken) // App's copy
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.refreshToken) // App's copy
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.sdkDeviceDetails)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.sdkSessionDetails)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.webToken)

        appViewModel?.logout()
        print("[HomeViewModel] Standard logout processed using SDK's clearSessionTokens for user: \(username).")
    }

    func webLoginButtonTapped() {
        navigateToWebLogin = true
    }
}
