//
//  HawcxDemoAppApp.swift
//  HawcxDemoApp
//
//  Created by Agam Bhullar on 4/14/25.
//

import SwiftUI

@main
struct HawcxDemoApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var sharedAuthManager = SharedAuthManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appViewModel) 
                .environmentObject(sharedAuthManager)
        }
    }
}
