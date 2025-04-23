//
//  Constants.swift
//  HawcxDemoApp
//
//  Created by Agam Bhullar on 4/14/25.
//

import Foundation

struct Constants {
    static let apiKey: String = "LmVKd2x5VXNLQWpFTUFOQzdaQzJTTnAwNGNlVk5TdHEwVUhTd3pBY1I4ZTRXM0w3M2dXTXJhMndHVjlqTHR0OFdiWTl6Zmk1d0F1MzlIODVUME0wR3JmcUsybHU4bF9kd25FUVZaUnFkZlhiQmVVU3VsaTZlaFdkaU5xdGlVbEppOWxJeHp6NHdVVVVqWWdzSTN4X1dfU1VmLlpyTDJqZy52cXVvUVMxVzZUemI5akFYY3ctMFAtT3NnSnk4dmhOLTJnci1CUnAtQlVEbEVoZlg1cW5IQ0tybmxtckQ0YkV4U2F0OUxRUk80YjJndHRfTHgyVzdsZw=="


    struct UserDefaultsKeys {
        static let lastUser = "lastLoggedInUser" // Key used by HawcxService saveLastUser/checkLastUser via frameworkUtils
        static let isLoggedOut = "isLoggedOut" // Key used by HawcxService logout
        static let biometricPrefix = "biometric_pref_" // Prefix for user-specific biometric preference
        static let enableBiometricsAfterLogin = "enable_biometrics_after_login"
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
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
