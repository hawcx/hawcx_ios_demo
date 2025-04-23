//
//  HomeViewModel.swift
//  HawcxDemoApp
//
//  Created by Agam Bhullar on 4/14/25.
//

import SwiftUI
import Combine
import HawcxFramework // Import the SDK framework


@MainActor // Ensure UI updates happen on the main thread
class HomeViewModel: ObservableObject, DevSessionCallback { // Conform to DevSessionCallback
    @Published var username: String = ""
    @Published var devices: [DeviceSessionInfo] = [] // To hold fetched device details
    @Published var isLoading: Bool = false // To show loading state
    var onWebLoginRequested: (() -> Void)?

    weak var appViewModel: AppViewModel? // Use weak reference
    private var devSessionManager: DevSession // SDK component instance

    init(appViewModel: AppViewModel?) {
        self.appViewModel = appViewModel
        self.devSessionManager = DevSession(apiKey: Constants.apiKey)

        if let loggedInUser = appViewModel?.loggedInUsername {
            self.username = loggedInUser
        } else {
            self.username = "User" // Default fallback
        }
    }

    convenience init() {
        self.init(appViewModel: nil)
        self.username = "preview.user@example.com" // Example for preview
        self.devices = [
            DeviceSessionInfo(devId: "preview-dev-1", osDetails: "iOS 17 Preview", browserWithVersion: "Safari Preview", deviceType: "iPhone Preview", sessionDetails: [
                SessionInfo(country: "Previewland", ipDetails: "127.0.0.1", isp: "Preview ISP", sessionLoginTime: "Now", osDetails: "iOS 17 Preview")
            ])
        ]
    }

    func fetchDeviceDetails() {
        isLoading = true
        devSessionManager.GetDeviceDetails(callback: self)
    }

    func logoutButtonTapped() {
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.lastUser)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.accessToken) // If stored directly
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.refreshToken) // If stored directly
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.sdkDeviceDetails)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.sdkSessionDetails)
        if !username.isEmpty {
            UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.biometricPrefix + username)
        }

        appViewModel?.logout() // AppViewModel should handle setting isLoggedIn to false and navigating
    }

    func navigateToWebLogin() {
        onWebLoginRequested?()
    }

    nonisolated func onSuccess() {
        // Explicit main thread dispatch for UI updates
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.isLoading = false
            do {
                if let savedData = UserDefaults.standard.data(forKey: Constants.UserDefaultsKeys.sdkDeviceDetails) {
                    let decoder = JSONDecoder()
                    let decodedDevices = try decoder.decode([DeviceSessionInfo].self, from: savedData)
                    self.devices = decodedDevices
                } else {
                    self.devices = []
                }
            } catch {
                self.appViewModel?.alertInfo = AlertInfo(title: "Error", message: "Could not load device information.")
                self.devices = []
            }
        }
    }
    
    nonisolated func showError() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.isLoading = false
            self.appViewModel?.alertInfo = AlertInfo(title: "Error", message: "Failed to fetch device session information. Please try again later.")
            self.devices = []
        }
    }
}
