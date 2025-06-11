//
//  QRScannerViewModel.swift
//  HawcxDemoApp
//
//  Created on 4/15/25.
//

import SwiftUI
import AVFoundation

// MARK: - ViewModel
// HawcxDemoApp/QRScannerViewModel.swift
// ... (keep existing imports and properties) ...

//@MainActor
class QRScannerViewModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var isShowingCamera = false
    @Published var permissionDenied = false
    @Published var isScanning = false // Flag to prevent re-entry
    @Published var scannedCode = ""
    @Published var errorMessage = ""

    // Strong reference to capture session
    let captureSession = AVCaptureSession()
    private var isSessionConfigured = false
    private var metadataOutput: AVCaptureMetadataOutput?

    override init() {
        super.init()
        print("[QRScannerViewModel] Initialized")
    }

    deinit {
        print("[QRScannerViewModel] Deinitializing")
        // Ensure session is stopped on deinit
        if captureSession.isRunning {
            captureSession.stopRunning()
            metadataOutput?.setMetadataObjectsDelegate(nil, queue: nil)
            print("[QRScannerViewModel] Capture session stopped during deinit")
        }
    }

    func checkCameraPermission() {
        print("[QRScannerViewModel] Checking camera permission")

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            print("[QRScannerViewModel] Camera permission not determined, requesting access")
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if granted {
                        self.setupCaptureSession()
                    } else {
                        self.permissionDenied = true
                        print("[QRScannerViewModel] Camera permission denied by user")
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.permissionDenied = true
                print("[QRScannerViewModel] Camera permission denied or restricted")
            }
        @unknown default:
            break
        }
    }

    func setupCaptureSession() {
        print("[QRScannerViewModel] Setting up capture session")
        if isSessionConfigured {
            print("[QRScannerViewModel] Session already configured, skipping setup.")
            // Ensure it's running if already configured but stopped
             if !captureSession.isRunning {
                 startCaptureSession()
             }
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            self.resetCaptureSession() // Ensure clean state

            guard let videoDevice = AVCaptureDevice.default(for: .video) else {
                self.handleSetupError("Could not find a video device")
                return
            }

            do {
                self.captureSession.beginConfiguration()

                if self.captureSession.canSetSessionPreset(.high) {
                    self.captureSession.sessionPreset = .high
                }

                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                if self.captureSession.canAddInput(videoInput) {
                    self.captureSession.addInput(videoInput)
                    print("[QRScannerViewModel] Added video input to capture session")
                } else {
                    self.handleSetupError("Could not add video input")
                    self.captureSession.commitConfiguration()
                    return
                }

                let metadataOutput = AVCaptureMetadataOutput()
                self.metadataOutput = metadataOutput // Store reference

                if self.captureSession.canAddOutput(metadataOutput) {
                    self.captureSession.addOutput(metadataOutput)
                    // IMPORTANT: Set delegate *before* setting metadataObjectTypes
                    metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)

                    if metadataOutput.availableMetadataObjectTypes.contains(.qr) {
                         metadataOutput.metadataObjectTypes = [.qr]
                         print("[QRScannerViewModel] Added metadata output for QR codes")
                    } else {
                        self.handleSetupError("QR code detection not supported")
                        self.captureSession.commitConfiguration()
                        return
                    }
                } else {
                    self.handleSetupError("Could not add metadata output")
                    self.captureSession.commitConfiguration()
                    return
                }

                self.captureSession.commitConfiguration()
                self.isSessionConfigured = true
                self.startCaptureSession() // Start after successful configuration

            } catch {
                self.handleSetupError("Error setting up camera: \(error.localizedDescription)")
                self.captureSession.commitConfiguration() // Ensure configuration is committed even on error
            }
        }
    }

    private func resetCaptureSession() {
        // Should be called on the same queue as setup
        if captureSession.isRunning {
            captureSession.stopRunning()
            print("[QRScannerViewModel] Resetting: Stopped running session.")
        }
        // Remove inputs/outputs safely
        captureSession.beginConfiguration()
        captureSession.inputs.forEach { captureSession.removeInput($0) }
        captureSession.outputs.forEach { captureSession.removeOutput($0) }
        captureSession.commitConfiguration()
        metadataOutput = nil // Clear reference
        isSessionConfigured = false // Mark as not configured
        print("[QRScannerViewModel] Resetting: Inputs and outputs removed.")
    }


    private func startCaptureSession() {
        guard isSessionConfigured else {
             print("[QRScannerViewModel] Cannot start session: Not configured.")
             checkCameraPermission() // Try re-configuring
             return
         }
        
        // Start the session on a background queue if not already running
        if !captureSession.isRunning {
             DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                 self?.captureSession.startRunning()
                 print("[QRScannerViewModel] Capture session started")
                 DispatchQueue.main.async {
                     self?.isShowingCamera = true
                 }
             }
         } else {
             print("[QRScannerViewModel] Capture session already running.")
             DispatchQueue.main.async { [weak self] in
                 self?.isShowingCamera = true
             }
         }
    }


    private func handleSetupError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.errorMessage = message
            self.isSessionConfigured = false // Ensure state reflects error
            print("[QRScannerViewModel] Camera setup error: \(message)")
        }
    }

    func startScanning() {
        print("[QRScannerViewModel] Start scanning requested")
        // Reset state before starting
        isScanning = false
        scannedCode = ""
        errorMessage = ""

        checkCameraPermission() // This will setup and start if needed
    }

    func stopScanning() {
        print("[QRScannerViewModel] Stop scanning requested")
        guard captureSession.isRunning else {
            print("[QRScannerViewModel] Stop scanning: Session already stopped.")
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
             guard let self = self else { return }
             self.captureSession.stopRunning()
             DispatchQueue.main.async {
                // Remove delegate safely on main thread after stopping
                self.metadataOutput?.setMetadataObjectsDelegate(nil, queue: nil)
                self.isShowingCamera = false // Update UI
                print("[QRScannerViewModel] Capture session stopped and delegate cleared.")
            }
        }
    }

    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Prevent processing if already scanning, navigating back, or error shown
        guard !isScanning, errorMessage.isEmpty else {
            return
        }

        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let stringValue = metadataObject.stringValue,
           metadataObject.type == .qr {

            // --- FIX: Stop session immediately upon finding a potential code ---
            // Stop running the session *before* processing to prevent rapid re-scans
            // We do this on the delegate queue (main thread)
             if captureSession.isRunning {
                 captureSession.stopRunning()
                 print("[QRScannerViewModel] Capture session stopped immediately after QR detection.")
            }
           
            // Set scanning flag AFTER stopping
            isScanning = true
            print("[QRScannerViewModel] QR code scanned: \(stringValue)")

            // Play success haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            // Extract PIN
            let extractedPin = self.extractHawcxPin(from: stringValue)

            if !extractedPin.isEmpty {
                print("[QRScannerViewModel] Valid PIN found: \(extractedPin)")
                // Update the published property which will trigger the .onChange in the View
                self.scannedCode = extractedPin
                // No need to call stopScanning() again here, it was stopped above.
                // The .onChange in the View will handle dismissal and the onScanSuccess callback.
            } else {
                print("[QRScannerViewModel] Invalid QR code format. No valid 7-digit PIN found in: \(stringValue)")
                self.errorMessage = "Invalid QR code format. Expected a Hawcx login code with a 7-digit PIN."
                 // Reset scanning flag as it was an invalid code, allow retrying
                 isScanning = false
                 // Restart the session to allow scanning again after showing the error
                 startCaptureSession()
            }
        }
    }

    // PIN extraction logic (no changes needed here)
    private func extractHawcxPin(from code: String) -> String {
        if code.count == 7 && code.allSatisfy({ $0.isNumber }) {
            return code
        }
        let patterns = [
            "pin=([0-9]{7})", "PIN=([0-9]{7})",
            "code=([0-9]{7})", "CODE=([0-9]{7})",
            "token=([0-9]{7})", "TOKEN=([0-9]{7})",
            "\\b([0-9]{7})\\b" // Look for exactly 7 digits as a word boundary
        ]
        for pattern in patterns {
            if let pin = extractWithRegex(pattern: pattern, from: code) {
                return pin
            }
        }
        return ""
    }

    private func extractWithRegex(pattern: String, from string: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(location: 0, length: string.utf16.count)
        if let match = regex.firstMatch(in: string, options: [], range: range),
           match.numberOfRanges > 1,
           let captureRange = Range(match.range(at: 1), in: string) {
            return String(string[captureRange])
        }
        return nil
    }
}
