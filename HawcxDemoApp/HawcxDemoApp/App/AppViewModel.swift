//
//  AppViewModel.swift
//  HawcxDemoApp
//
//  Updated on 4/15/25.
//
// AppViewModel.swift
import SwiftUI
import Combine
import HawcxFramework

enum AuthenticationState {
    case checking
    case loggedOut
    case loggedIn
}

enum AppView: Hashable {
    case authenticate
    case home
    case webLogin
}

@MainActor
class AppViewModel: ObservableObject {
    @Published var authenticationState: AuthenticationState = .checking
    @Published var loggedInUsername: String? = nil
    
    @Published var alertInfo: AlertInfo? = nil
    @Published var loadingAlertInfo: LoadingAlertInfo? = nil
    @Published var toast: Toast? = nil // <<< NEW PROPERTY FOR TOAST

    init() {
        checkInitialAuthenticationState()
    }
    
    func checkInitialAuthenticationState() {
        authenticationState = .checking
        let sdk = HawcxSDK(projectApiKey: Constants.apiKey)
        let sdkLastUser = sdk.getLastLoggedInUser()

        if !sdkLastUser.isEmpty {
            print("[AppViewModel] Found SDK last user: \(sdkLastUser). Considering this for initial state.")
            loggedInUsername = sdkLastUser
            authenticationState = .loggedOut
        } else if let appLastUser = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.lastUser) {
            print("[AppViewModel] Found app's last user: \(appLastUser). SDK had no last user.")
            loggedInUsername = appLastUser
            authenticationState = .loggedOut
        }
        else {
            print("[AppViewModel] No last user found (SDK or App).")
            authenticationState = .loggedOut
        }
    }
    
    func userDidLogin(username: String) {
        print("[AppViewModel] User login/auth process successful for: \(username)")
        
        if authenticationState == .loggedIn && loggedInUsername == username {
            print("[AppViewModel] Already logged in as \(username). State consistent.")
//            clearAlertsAndToast() // Clear any loading alerts or toasts
            clearAlerts()
            return
        }
        
        loggedInUsername = username
        UserDefaults.standard.set(username, forKey: Constants.UserDefaultsKeys.lastUser)
        
        authenticationState = .loggedIn
//        clearAlertsAndToast() // Ensure any loading alerts or toasts from auth process are cleared
        clearAlerts()
        print("[AppViewModel] Authentication complete. State updated to .loggedIn for \(username).")
    }
    
    func logout() {
        print("[AppViewModel] User logged out.")
        loggedInUsername = nil
        authenticationState = .loggedOut
        clearAlertsAndToast()
    }
    
    func showAlert(title: String, message: String) {
        toast = nil // Clear toast if showing an alert
        loadingAlertInfo = nil
        alertInfo = AlertInfo(title: title, message: message)
    }
    
    func showLoadingAlert(title: String, message: String) {
        toast = nil // Clear toast if showing a loading alert
        alertInfo = nil
        loadingAlertInfo = LoadingAlertInfo(title: title, message: message)
    }

    func showToast(style: ToastStyle, message: String, duration: Double = 3.0) { // <<< NEW METHOD
        alertInfo = nil // Clear alert if showing a toast
        loadingAlertInfo = nil
        toast = Toast(style: style, message: message, duration: duration)
    }
    
    func clearAlerts() {
        alertInfo = nil
        loadingAlertInfo = nil
    }

    func clearToast() { // <<< NEW METHOD
        toast = nil
    }

    func clearAlertsAndToast() { // <<< NEW METHOD
        alertInfo = nil
        loadingAlertInfo = nil
        toast = nil
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
