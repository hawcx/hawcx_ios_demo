//
//  Models.swift
//  HawcxDemoApp
//
//  Created by Agam Bhullar on 4/14/25.
//

import Foundation


struct AlertInfo: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

struct LoadingAlertInfo: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}


struct DeviceSessionInfo: Codable, Identifiable, Hashable {
    let id = UUID() // Added for Identifiable conformance in SwiftUI lists
    let devId: String
    let osDetails: String
    let browserWithVersion: String
    let deviceType: String
    let sessionDetails: [SessionInfo]

    enum CodingKeys: String, CodingKey {
        case devId = "dev_id"
        case osDetails = "os_details"
        case browserWithVersion = "browser_with_version"
        case deviceType = "device_type"
        case sessionDetails = "session_details"
    }
}

struct SessionInfo: Codable, Identifiable, Hashable {
    let id = UUID() // Added for Identifiable conformance in SwiftUI lists
    let country: String
    let ipDetails: String
    let isp: String
    let sessionLoginTime: String
    let osDetails: String // Note: This might be redundant if parent DeviceSessionInfo has it

    enum CodingKeys: String, CodingKey {
        case country
        case ipDetails = "ip_details"
        case isp
        case sessionLoginTime = "session_login_time"
        case osDetails = "os_details" // Matches the key from the reference JSON
    }
}
