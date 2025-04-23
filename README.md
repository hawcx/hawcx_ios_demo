# Hawcx Demo App

[![Swift Version](https://img.shields.io/badge/Swift-5.0+-orange.svg)](https://swift.org)

[![Platform](https://img.shields.io/badge/platform-iOS_17.0+-blue.svg)](https://developer.apple.com/ios/)

[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A comprehensive demonstration application showcasing the [Hawcx iOS SDK](https://github.com/hawcx/hawcx_ios_sdk) for passwordless authentication.

<img src="Assets/Hawcx_Logo.png" alt="Hawcx Demo App" width="200" />

## Features

### 🔐 Passwordless Authentication
- **No password required** - Authenticate users securely without the hassle of passwords
- **Email verification** - Simple OTP-based verification through email
- **Enterprise-grade security** - Backed by Hawcx's robust security infrastructure

### 📱 Multi-Device Support
- **Seamless device registration** - Add new devices to your account with simple verification
- **Cross-device login** - Access your account from any registered device
- **Session management** - View and manage all your active devices

### 👆 Biometric Authentication
- **Face ID & Touch ID integration** - Log in quickly with biometric authentication
- **Opt-in biometrics** - User-friendly prompts to enable biometric login
- **Secure implementation** - Uses Apple's LocalAuthentication framework

### 💻 Modern SwiftUI Implementation
- **Complete SwiftUI app** - Built entirely with Apple's latest UI framework
- **MVVM architecture** - Clean separation of concerns with ViewModels
- **Comprehensive error handling** - User-friendly error messages and recovery flows

## Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- Swift 5.0+
- [Hawcx iOS SDK](https://github.com/hawcx/hawcx_ios_sdk)

### Installation

1. Clone this repository:
```bash
git clone https://github.com/hawcx/hawcx_ios_demo.git
```

2. Open the `HawcxDemoApp.xcodeproj` file in Xcode.

3. Configure your API key:
   - Open `Constants.swift`
   - Replace the placeholder API key with your actual Hawcx API key

```swift
struct Constants {
    static let apiKey = "YOUR_API_KEY_HERE"
    // ...
}
```

4. Build and run the project on a simulator or physical device.

## App Architecture

The demo app is built with a clean MVVM architecture:

### Views
- `LoginView` - Email login and biometric authentication
- `SignUpView` - New user registration with OTP verification
- `AddDeviceView` - Register new devices to an existing account
- `HomeView` - Post-login view with user details and device management

### ViewModels
- `LoginViewModel` - Handles authentication logic and biometric integration
- `SignUpViewModel` - Manages user registration flow
- `AddDeviceViewModel` - Controls device registration process
- `HomeViewModel` - Manages logged-in user state and device information

### Core Components
- `AppViewModel` - Central state management for authentication status
- `SharedAuthManager` - Facilitates communication between authentication components
- `BiometricService` - Wrapper for LocalAuthentication framework integration

## SDK Integration

The demo app demonstrates complete integration with the Hawcx SDK:

```swift
import HawcxFramework

// Initialize the SDK
HawcxInitializer.shared.initialize(apiKey: Constants.apiKey)

// User authentication
let signIn = SignIn(apiKey: Constants.apiKey)
signIn.signIn(userid: email, callback: self)

// User registration
let signUp = SignUp(apiKey: Constants.apiKey)
signUp.signUp(userid: email, callback: self)

// Device management
let addDeviceManager = AddDeviceManager(apiKey: Constants.apiKey)
addDeviceManager.startAddDeviceFlow(userid: email, callback: self)

// Session information
let devSession = DevSession(apiKey: Constants.apiKey)
devSession.GetDeviceDetails(callback: self)
```

## User Flows

### Registration
1. User enters email address
2. OTP is sent to the email
3. User verifies with OTP
4. Account is created and user is automatically logged in

### Login
1. User enters registered email
2. Authentication is completed automatically
3. Biometric login prompt is shown for future logins

### Add Device
1. User attempts to log in on a new device
2. Device registration flow is initiated
3. OTP verification confirms user identity
4. Device is added to the account

## Best Practices Demonstrated

- **Secure Authentication**: Implementation of passwordless authentication
- **Biometric Security**: Proper integration of Face ID and Touch ID
- **Error Handling**: Comprehensive error handling and user feedback
- **State Management**: Clean state management across the authentication flow
- **UI/UX Design**: User-friendly interfaces for authentication processes

## Resources

- [Hawcx iOS SDK](https://github.com/hawcx/hawcx_ios_sdk)
- [Documentation](https://docs.hawcx.com)
- [API Reference](https://docs.hawcx.com/ios/quickstart)
- [Website](https://www.hawcx.com)
- [Support Email](mailto:info@hawcx.com)

## License

This demo app is available under the MIT license. See the LICENSE file for more info.
