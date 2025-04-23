//
//  AppViewModel.swift
//  HawcxDemoApp
//
//  Updated on 4/15/25.
//

import SwiftUI
import Combine

enum AuthenticationState {
    case checking // Initial state while checking last user/biometrics
    case loggedOut
    case loggedIn
}

enum AppView: Hashable {
    case login
    case signUp
    case resetDevice(initialEmail: String? = nil) // Pass initial email if needed
    case home
}

@MainActor
class AppViewModel: ObservableObject {
    // Core app state
    @Published var authenticationState: AuthenticationState = .checking
    @Published var loggedInUsername: String? = nil
    
    // Global UI state
    @Published var isLoading: Bool = false // Keep this for backward compatibility
    @Published var alertInfo: AlertInfo? = nil
    @Published var loadingAlertInfo: LoadingAlertInfo? = nil
    
    init() {
        checkInitialAuthenticationState()
    }
    
    func checkInitialAuthenticationState() {
        authenticationState = .checking
        
        // We're not setting isLoading = true here anymore
        
        if let lastUser = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.lastUser) {
            loggedInUsername = lastUser
            authenticationState = .loggedOut // Start as logged out, view will handle login attempt
        } else {
            authenticationState = .loggedOut
        }
        
        // We're not setting isLoading = false here anymore
    }
    
    func userDidLogin(username: String) {
        loggedInUsername = username
        authenticationState = .loggedIn
        // We're not setting isLoading = false here anymore
    }
    
    func logout() {
        // We're not setting isLoading = true here anymore
        loggedInUsername = nil
        authenticationState = .loggedOut
        // We're not setting isLoading = false here anymore
    }
    
    func showAlert(title: String, message: String) {
        // Clear any loading alert first
        loadingAlertInfo = nil
        // Show regular alert
        alertInfo = AlertInfo(title: title, message: message)
    }
    
    func showLoadingAlert(title: String, message: String) {
        // Clear any regular alert first
        alertInfo = nil
        // Show loading alert
        loadingAlertInfo = LoadingAlertInfo(title: title, message: message)
    }
    
    func clearAlerts() {
        alertInfo = nil
        loadingAlertInfo = nil
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
