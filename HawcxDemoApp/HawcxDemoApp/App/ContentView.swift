//
//  ContentView.swift
//  HawcxDemoApp
//
//  Created by Agam Bhullar on 4/14/25.
//

// ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    var body: some View {
        ZStack {
            Group {
                switch appViewModel.authenticationState {
                case .checking:
                    ProgressView("Checking Status...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                
                case .loggedOut:
                    NavigationStack {
                        WelcomeView()
                            .environmentObject(appViewModel)
                    }
                
                case .loggedIn:
                    NavigationStack {
                        HomeView()
                            .environmentObject(appViewModel)
                    }
                }
            }
            .zIndex(0)
        }
        .customAlert( // Regular dismissible alert
            isPresented: Binding<Bool>(
                get: { appViewModel.alertInfo != nil },
                set: { if !$0 { appViewModel.alertInfo = nil } }
            ),
            title: appViewModel.alertInfo?.title ?? "Error",
            message: appViewModel.alertInfo?.message ?? "An unknown error occurred."
        )
        .loadingAlert( // Non-dismissible loading alert
            isPresented: Binding<Bool>(
                get: { appViewModel.loadingAlertInfo != nil },
                set: { if !$0 { appViewModel.loadingAlertInfo = nil } }
            ),
            title: appViewModel.loadingAlertInfo?.title ?? "Loading",
            message: appViewModel.loadingAlertInfo?.message ?? "Please wait..."
        )
        .toastView(toast: $appViewModel.toast) // <<< ADD THIS MODIFIER FOR TOASTS
        .environmentObject(appViewModel)
        .animation(.easeInOut, value: appViewModel.authenticationState)
    }
}
