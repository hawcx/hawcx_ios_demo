//
//  RealQRScannerView.swift
//  HawcxDemoApp
//
//  Updated on 4/15/25.
//

import SwiftUI
import AVFoundation

struct RealQRScannerView: View {
    @StateObject private var viewModel = QRScannerViewModel()
    @State private var isNavigatingBack = false
    @Environment(\.dismiss) private var dismiss
    
    var onScanSuccess: (String) -> Void
    var onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            if viewModel.isShowingCamera {
                // Camera preview - using our improved CameraPreview
                CameraPreview(captureSession: viewModel.captureSession)
                    .ignoresSafeArea()
                
                // Viewfinder overlay with corner indicators
                GeometryReader { geometry in
                    let size = min(geometry.size.width, geometry.size.height) * 0.7
                    
                    ZStack {
                        // Semi-transparent overlay
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .mask(
                                Rectangle()
                                    .ignoresSafeArea()
                                    .overlay(
                                        Rectangle()
                                            .frame(width: size, height: size)
                                            .position(x: geometry.size.width/2, y: geometry.size.height/2)
                                            .blendMode(.destinationOut)
                                    )
                            )
                        
                        // Scanning frame with animation
                        ZStack {
                            // Main frame
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.red, lineWidth: 3)
                                .frame(width: size, height: size)
                                .position(x: geometry.size.width/2, y: geometry.size.height/2)
                            
                            // Scanning line animation
                            Rectangle()
                                .fill(Color.red.opacity(0.5))
                                .frame(width: size - 10, height: 2)
                                .position(x: geometry.size.width/2, y: geometry.size.height/2 + scannerLineOffset())
                        }
                        
                        // Corner indicators
                        ForEach(0..<4) { i in
                            Rectangle()
                                .fill(Color.red)
                                .frame(
                                    width: i % 2 == 0 ? 40 : 3,
                                    height: i % 2 == 0 ? 3 : 40
                                )
                                .position(
                                    x: geometry.size.width/2 + (i < 2 ? -size/2 : size/2) + (i % 2 == 0 ? 0 : (i == 1 ? 20 : -20)),
                                    y: geometry.size.height/2 + (i < 2 ? -size/2 : size/2) + (i % 2 == 0 ? (i == 0 ? -20 : 20) : 0)
                                )
                        }
                    }
                }
            }
            
            VStack {
                // Top info/instructions
                VStack(spacing: 10) {
                    Text("QR Scanner")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if viewModel.permissionDenied {
                        Text("Camera access is required for scanning QR codes. Please enable it in Settings.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                            .multilineTextAlignment(.center)
                    } else if !viewModel.isShowingCamera {
                        Text("Initializing camera...")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                    } else {
                        VStack(spacing: 8) {
                            Text("Scan the Hawcx Web Login QR Code")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                                .multilineTextAlignment(.center)
                            
                            Text("The QR code should contain a 7-digit PIN")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding(.top, 50)
                
                Spacer()
                
                // Bottom controls
                VStack(spacing: 15) {
                    if viewModel.permissionDenied {
                        Button(action: {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text("Open Settings")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 30)
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                    } else {
                        // Manual entry button
                        Button(action: {
                            guard !isNavigatingBack && !viewModel.isScanning else { return }
                            isNavigatingBack = true
                            viewModel.stopScanning()
                            dismiss()
                            onDismiss()
                        }) {
                            Text("Enter PIN Manually")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 30)
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                        .disabled(isNavigatingBack || viewModel.isScanning)
                        .opacity((isNavigatingBack || viewModel.isScanning) ? 0.5 : 1.0)
                        
                        // Cancel button
                        Button(action: {
                            guard !isNavigatingBack && !viewModel.isScanning else { return }
                            isNavigatingBack = true
                            viewModel.stopScanning()
                            dismiss()
                            onDismiss()
                        }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 30)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(10)
                        }
                        .disabled(isNavigatingBack || viewModel.isScanning)
                        .opacity((isNavigatingBack || viewModel.isScanning) ? 0.5 : 1.0)
                    }
                }
                .padding(.bottom, 50)
            }
            .padding(.horizontal)
            
            // Loading indicator
            if viewModel.isScanning || isNavigatingBack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .frame(width: 50, height: 50)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
            }
            
            // Error message
            if !viewModel.errorMessage.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.yellow)
                    
                    Text("Scan Error")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(viewModel.errorMessage)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    Button(action: {
                        viewModel.errorMessage = ""
                        viewModel.isScanning = false
                    }) {
                        Text("Try Again")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                }
                .padding(30)
                .background(Color.black.opacity(0.8))
                .cornerRadius(15)
                .padding()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Start scanning when view appears
            viewModel.startScanning()
        }
        .onDisappear {
            // Clean up when view disappears
            viewModel.stopScanning()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    viewModel.stopScanning()
                    dismiss()
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
        }
        .onChange(of: viewModel.scannedCode) { code in
            if !code.isEmpty && viewModel.isScanning && viewModel.errorMessage.isEmpty {
                // Pass the scanned code back through the callback
                viewModel.stopScanning()
                dismiss()
                onScanSuccess(code)
            }
        }
    }
    
    // Animation effect for scanner line
    private func scannerLineOffset() -> CGFloat {
        let animation = Animation
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        
        return withAnimation(animation) {
            CGFloat.random(in: -80...80)
        }
    }
}

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    let captureSession: AVCaptureSession
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.session = captureSession
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        
        print("Camera preview layer setup with session")
        
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Nothing to update
    }
    
    // Custom UIView that contains an AVCaptureVideoPreviewLayer
    class PreviewView: UIView {
        override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
}
