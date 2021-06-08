/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller for recognizing barcodes.
*/

import AVFoundation
import SwiftUI
import UIKit

/// `BarcodeScanningViewController` is a view controller that can be used to recognize regular one dimensional barcodes.
/// This is accomplished using `AVCaptureSession` and `AVCaptureVideoPreviewLayer`.
class BarcodeScanningViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    // MARK: - Object lifecycle
    
    init(_ detectedBarcode: Binding<String>) {
        self._detectedBarcode = detectedBarcode
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Properties
    
    /// A barcode string scanned via the barcode scanning view.
    @Binding var detectedBarcode: String
    
    /// A capture session used to enable the camera.
    private var captureSession: AVCaptureSession?
    
    /// The capture session's preview content.
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        // Set up the capture device.
        let captureSession = AVCaptureSession()
        let metadataOutput = AVCaptureMetadataOutput()
        if
            let videoCaptureDevice = AVCaptureDevice.default(for: .video),
            let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
            captureSession.canAddInput(videoInput),
            captureSession.canAddOutput(metadataOutput) {
            
            // Configure the capture session.
            self.captureSession = captureSession
            captureSession.addInput(videoInput)
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13]
            
            // Configure the preview layer.
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            self.previewLayer = previewLayer
            
            previewLayer.frame = view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            
            // Start the capture session.
            captureSession.startRunning()
        } else {
            let scanningUnsupportedAlertController = UIAlertController(
                title: "Scanning not supported",
                message: "Your device does not support scanning a code from an item. Please use a device with a camera.",
                preferredStyle: .alert
            )
            let okAlertAction = UIAlertAction(title: "OK", style: .default)
            scanningUnsupportedAlertController.addAction(okAlertAction)
            present(scanningUnsupportedAlertController, animated: true)
        }
    }
    
    /// Resumes the current capture session, if any, when the view appears.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let captureSession = self.captureSession, !captureSession.isRunning {
            captureSession.startRunning()
        }
    }
    
    /// Suspends the current capture session, if any, when the view disappears.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let captureSession = self.captureSession, captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    /// Hides the status bar when a capture is running.
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    /// Forces this view into portrait orientation.
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    // MARK: - Capture metadata output objects delegate
    
    /// Captures a barcode string, if found in the current capture session.
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        self.captureSession?.stopRunning()
        
        // Check that a barcode is available.
        if
            let previewLayer = self.previewLayer,
            let metadataObject = metadataObjects.first,
            let readableObject = previewLayer.transformedMetadataObject(for: metadataObject) as? AVMetadataMachineReadableCodeObject,
            let detectedBarcode = readableObject.stringValue {
            
            // Provide haptic feedback when a barcode is recognized.
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            // Display the recognized barcode string as UI feedback.
            var barcodeBounds = CGRect(origin: previewLayer.position, size: .zero)
            var barcodeCorners = readableObject.corners
            if !barcodeCorners.isEmpty {
                let barcodePath = UIBezierPath()
                let firstCorner = barcodeCorners.removeFirst()
                barcodePath.move(to: firstCorner)
                for corner in barcodeCorners {
                    barcodePath.addLine(to: corner)
                }
                barcodePath.close()
                barcodeBounds = barcodePath.bounds
                
                addAnimatedBarcodeShape(with: barcodePath, to: previewLayer)
            }
            showLabel(for: detectedBarcode, avoiding: barcodeBounds)
            
            // Remember the recognized barcode string.
            self.detectedBarcode = detectedBarcode
        }
    }
    
    // MARK: - Display detected barcode
    
    /// Highlights the recognized barcode.
    private func addAnimatedBarcodeShape(with barcodePath: UIBezierPath, to parentLayer: CALayer) {
        let barcodeShapeLayer = CAShapeLayer()
        barcodeShapeLayer.path = barcodePath.cgPath
        barcodeShapeLayer.strokeColor = view.tintColor.cgColor
        barcodeShapeLayer.lineWidth = 3.0
        barcodeShapeLayer.lineJoin = .round
        barcodeShapeLayer.lineCap = .round
        
        let barcodeBounds = barcodePath.bounds
        barcodeShapeLayer.bounds = barcodeBounds
        barcodeShapeLayer.position = CGPoint(x: barcodeBounds.midX, y: barcodeBounds.midY)
        barcodeShapeLayer.masksToBounds = true
        parentLayer.addSublayer(barcodeShapeLayer)
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.autoreverses = true
        opacityAnimation.duration = 0.3
        opacityAnimation.repeatCount = 5
        opacityAnimation.toValue = 0.0
        barcodeShapeLayer.add(opacityAnimation, forKey: opacityAnimation.keyPath)
    }
    
    /// Shows the recognized barcode string.
    private func showLabel(for detectedBarcode: String, avoiding barcodeBounds: CGRect) {
        let fontSize = 32.0
        let cornerRadius = 8.0
        
        let label = UILabel()
        label.text = detectedBarcode
        label.font = .systemFont(ofSize: fontSize, weight: .bold)
        label.textAlignment = .center
        label.textColor = .label
        label.sizeToFit()
        
        let labelContainer = UIView()
        labelContainer.backgroundColor = .systemBackground.withAlphaComponent(0.6)
        labelContainer.layer.cornerRadius = cornerRadius
        labelContainer.bounds = CGRect(origin: .zero, size: label.bounds.insetBy(dx: -cornerRadius, dy: -cornerRadius).size)
        label.center = CGPoint(x: labelContainer.bounds.midX, y: labelContainer.bounds.midY)
        labelContainer.addSubview(label)
        
        let parentViewBounds = view.bounds
        let normalizedVerticalOffset = (barcodeBounds.midY < parentViewBounds.midY) ? 0.80 : 0.20
        let verticalOffset = parentViewBounds.minY + ((parentViewBounds.maxY - parentViewBounds.minY) * normalizedVerticalOffset)
        labelContainer.center = CGPoint(x: parentViewBounds.midX, y: verticalOffset)
        
        let scale = 0.01
        labelContainer.transform = CGAffineTransform(scaleX: scale, y: scale)
        view.addSubview(labelContainer)
        
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.0, options: []) {
            labelContainer.transform = .identity
        }
    }
}
