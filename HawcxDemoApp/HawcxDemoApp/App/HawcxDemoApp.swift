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
//    init() {
//        loadRocketSimConnect()
//    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appViewModel) 
                .environmentObject(sharedAuthManager)
        }
    }
}

//private func loadRocketSimConnect() {
//    #if DEBUG
//    guard (Bundle(path: "/Applications/RocketSim.app/Contents/Frameworks/RocketSimConnectLinker.nocache.framework")?.load() == true) else {
//        print("Failed to load linker framework")
//        return
//    }
//    print("RocketSim Connect successfully linked")
//    #endif
//}
