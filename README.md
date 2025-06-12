# Hawcx Demo App - iOS (V4)

[![Swift Version](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS_14.0+-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A comprehensive demonstration application showcasing the [Hawcx iOS SDK V4](https://github.com/hawcx/hawcx_ios_sdk) for passwordless authentication with unified authentication flows.

<img src="Assets/Hawcx_Logo.png" alt="Hawcx Demo App" width="200" />

## What's New in V4

### 🚀 Unified Authentication
- **Single API call** - `authenticateV4()` handles login, signup, and device registration in one method
- **Simplified integration** - Reduced complexity with fewer SDK methods to manage
- **Intelligent flow detection** - SDK automatically determines if it's a new user, returning user, or new device

### 🔄 Enhanced User Experience
- **Seamless transitions** - Smooth flow between registration and login without additional calls
- **Improved error handling** - More specific error codes and better user feedback
- **Automatic session management** - JWT tokens handled automatically with secure Keychain storage

## Features

### 🔐 Passwordless Authentication
- **No password required** - Authenticate users securely without the hassle of passwords
- **Email verification** - Simple OTP-based verification through email
- **Enterprise-grade security** - Backed by Hawcx's robust security infrastructure
- **Unified authentication flow** - Single method handles all authentication scenarios

### 📱 Multi-Device Support
- **Seamless device registration** - Add new devices to your account with simple verification
- **Cross-device login** - Access your account from any registered device
- **Advanced session management** - Granular control over session tokens vs device registration

### 👆 Biometric Authentication
- **Face ID & Touch ID integration** - Log in quickly with biometric authentication
- **Opt-in biometrics** - User-friendly prompts to enable biometric login after successful authentication
- **Secure implementation** - Uses Apple's LocalAuthentication framework
- **Per-user biometric settings** - Individual biometric preferences for each user account

### 💻 Modern SwiftUI Implementation
- **Complete SwiftUI app** - Built entirely with Apple's latest UI framework
- **MVVM architecture** - Clean separation of concerns with ViewModels
- **Comprehensive error handling** - User-friendly error messages and recovery flows
- **Toast notifications** - Modern notification system for better user feedback

## Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 14.0+ (V4 requirement)
- Swift 5.9+
- [Hawcx iOS SDK V4](https://github.com/hawcx/hawcx_ios_sdk)

### Installation

1. Clone this repository:
```bash
git clone https://github.com/hawcx/hawcx-ios-demo.git
```

2. Open the `HawcxDemoApp.xcodeproj` file in Xcode.

3. Configure your API key:
   - Open `Constants.swift`
   - Replace the placeholder API key with your actual Hawcx V4 API key

```swift
struct Constants {
    static let apiKey = "YOUR_V4_API_KEY_HERE"
    // ...
}
```

4. Build and run the project on a simulator or physical device.

## Adding SDK to Your Own Project

### Option 1: Swift Package Manager (Recommended)

1. In Xcode, go to **File** → **Add Package Dependencies...**
2. In the search bar, enter: `https://github.com/hawcx/hawcx-sdk-ios`
3. Select the repository when it appears
4. Choose **Version** → **Up to Next Major Version** and enter `4.0.0`
5. Click **Add Package**
6. Select **HawcxFramework** target and click **Add Package**

### Option 2: Direct Download

1. Download the latest V4 release from [GitHub Releases](https://github.com/hawcx/hawcx_ios_sdk/releases/latest)
2. Drag `HawcxFramework.xcframework` into your project
3. Ensure it's added to your target's "Frameworks, Libraries, and Embedded Content"
4. Set "Embed" to "Embed & Sign"

## App Architecture

The demo app is built with a clean MVVM architecture optimized for V4:

### Views
- `AuthenticateView` - Unified authentication interface for all user scenarios
- `HomeView` - Post-authentication view with user details 
- `WebLoginView` - QR code and PIN-based web authentication
- `WelcomeView` - Landing screen with authentication options

### ViewModels
- `AuthenticateViewModel` - Handles all authentication logic using V4's unified approach
- `HomeViewModel` - Manages logged-in user state and device information
- `AppViewModel` - Central state management for authentication status
- `SharedAuthManager` - Facilitates automatic authentication and component communication

### Core Components
- `BiometricService` - Wrapper for LocalAuthentication framework integration
- `Toast System` - Modern notification system for user feedback
- `Constants` - Centralized configuration and UserDefaults keys

## V4 SDK Integration

The demo app demonstrates the simplified V4 integration:

```swift
import HawcxFramework

// Initialize the SDK (V4)
let sdk = HawcxSDK(projectApiKey: Constants.apiKey)

// Unified authentication - handles login, signup, and device registration
sdk.authenticateV4(userid: email, callback: self)

// Handle OTP when required
sdk.submitOtpV4(otp: otpCode)

// Session management (V4)
let lastUser = sdk.getLastLoggedInUser()
sdk.clearSessionTokens(forUser: userid)          // Standard logout
sdk.clearUserKeychainData(forUser: userid)       // Full device removal

// Web authentication
sdk.webLogin(pin: "1234567", callback: self)
sdk.webApprove(token: webToken, callback: self)
```

### V4 Callback Implementation

```swift
class AuthenticateViewModel: AuthV4Callback {
    func onOtpRequired() {
        // Show OTP input UI
        isOtpVisible = true
    }
    
    func onAuthSuccess(accessToken: String?, refreshToken: String?, isLoginFlow: Bool) {
        if isLoginFlow {
            // User successfully logged in
            navigateToHome()
        } else {
            // Device registration completed, will auto-trigger login
            showRegistrationCompleteMessage()
        }
    }
    
    func onError(errorCode: AuthV4ErrorCode, errorMessage: String) {
        // Handle authentication errors
        showError(message: errorMessage)
    }
}
```

## User Flows (V4)

### New User Registration
1. User enters email address
2. `authenticateV4()` is called
3. SDK detects new user and initiates registration
4. `onOtpRequired()` fires - OTP is sent to email
5. User verifies with OTP using `submitOtpV4()`
6. `onAuthSuccess()` fires with `isLoginFlow = false`
7. SDK automatically re-authenticates for login
8. `onAuthSuccess()` fires again with `isLoginFlow = true`
9. User is logged in and navigated to home screen

### Existing User Login
1. User enters registered email
2. `authenticateV4()` is called
3. SDK detects existing user on known device
4. `onAuthSuccess()` fires immediately with `isLoginFlow = true`
5. User is logged in directly (no OTP required)

### New Device Registration
1. User enters email on new device
2. `authenticateV4()` is called
3. SDK detects existing user on new device
4. `onOtpRequired()` fires - OTP is sent to email
5. User verifies with OTP using `submitOtpV4()`
6. `onAuthSuccess()` fires with `isLoginFlow = false` (device registered)
7. SDK automatically re-authenticates for login
8. `onAuthSuccess()` fires again with `isLoginFlow = true`
9. User is logged in on the new device

### Biometric Authentication
1. User with previously enabled biometrics opens app
2. Automatic biometric prompt appears
3. On successful biometric verification
4. `authenticateV4()` is called automatically
5. User is logged in instantly

## Best Practices Demonstrated

- **V4 Unified Flow**: Single authentication method for all scenarios
- **Secure Biometric Integration**: Proper Face ID and Touch ID implementation
- **Modern Error Handling**: Comprehensive error handling with user-friendly messages
- **Toast Notifications**: Modern feedback system instead of modal alerts
- **Automatic Re-authentication**: Seamless device registration to login flow
- **Session Management**: Proper distinction between logout and device removal
- **State Management**: Clean state management across authentication flows

## Migration from V3

If you're migrating from V3, here are the key changes:

### Before (V3):
```swift
// Multiple managers and methods
let signIn = SignIn(apiKey: apiKey)
let signUp = SignUp(apiKey: apiKey)
let addDevice = AddDeviceManager(apiKey: apiKey)

signIn.signIn(userid: email, callback: self)
signUp.signUp(userid: email, callback: self)
addDevice.startAddDeviceFlow(userid: email, callback: self)
```

### After (V4):
```swift
// Single SDK instance and method
let sdk = HawcxSDK(projectApiKey: apiKey)
sdk.authenticateV4(userid: email, callback: self)
```

## Resources

- [Hawcx iOS SDK](https://github.com/hawcx/hawcx_ios_sdk)
- [Documentation](https://docs.hawcx.com)
- [API Reference](https://docs.hawcx.com/ios/quickstart)
- [Website](https://www.hawcx.com)
- [Support Email](mailto:info@hawcx.com)

## License

This demo app is available under the MIT license. See the LICENSE file for more info.
