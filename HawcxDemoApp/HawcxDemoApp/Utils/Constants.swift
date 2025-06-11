//
//  Constants.swift
//  HawcxDemoApp
//
//  Created by Agam Bhullar on 4/14/25.
//

import Foundation

struct Constants {
    static let apiKey: String = "d58RMFc3mVjcnGaF8wBbULal96iSdvTY"


    struct UserDefaultsKeys {
        static let lastUser = "lastLoggedInUser" // Key used by HawcxService saveLastUser/checkLastUser via frameworkUtils
        static let isLoggedOut = "isLoggedOut" // Key used by HawcxService logout
        static let biometricPrefix = "biometric_pref_" // Prefix for user-specific biometric preference
        static let enableBiometricsAfterLogin = "enable_biometrics_after_login"
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
        static let webToken = "web_token" // Also used by HawcxService webLogin

        static let sdkDeviceDetails = "devDetails"
        static let sdkSessionDetails = "sessionDetails"
    }

    struct API {
    }

    struct UI {
    }
}

func isValidEmail(_ email: String) -> Bool {
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailPred.evaluate(with: email)
}

func isValidOTP(_ otp: String) -> Bool {
    return otp.count == 6 && otp.allSatisfy { $0.isNumber }
}
