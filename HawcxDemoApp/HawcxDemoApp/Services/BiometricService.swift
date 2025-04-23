//
//  BiometricService.swift
//  HawcxDemoApp
//
//  Created by Agam Bhullar on 4/14/25.
//

import LocalAuthentication
import Foundation

class BiometricService {
    private let context = LAContext()
    private var error: NSError?
    private let policy = LAPolicy.deviceOwnerAuthenticationWithBiometrics

    func canEvaluatePolicy() -> Bool {
        return context.canEvaluatePolicy(policy, error: &error)
    }

    func authenticate(completion: @escaping (Bool, Error?) -> Void) {
        guard canEvaluatePolicy() else {
            let errorInfo = error ?? NSError(domain: "BiometricServiceError", code: LAError.biometryNotAvailable.rawValue, userInfo: [NSLocalizedDescriptionKey: "Biometrics not available or not enrolled."])
            DispatchQueue.main.async {
                completion(false, errorInfo)
            }
            return
        }

        let reason = "Log in with Biometrics"

        context.evaluatePolicy(policy, localizedReason: reason) { success, authenticationError in
            DispatchQueue.main.async {
                if success {
                    completion(true, nil)
                } else {
                    completion(false, authenticationError)
                }
            }
        }
    }
}
