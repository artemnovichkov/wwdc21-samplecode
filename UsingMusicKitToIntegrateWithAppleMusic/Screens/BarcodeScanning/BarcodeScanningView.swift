/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View for recognizing barcodes.
*/

import SwiftUI

/// `BarcodeScanningView` presents UI for recognizing regular one dimensional barcodes.
struct BarcodeScanningView: UIViewControllerRepresentable {
    
    // MARK: - Object lifecycle
    
    init(_ detectedBarcode: Binding<String>) {
        self._detectedBarcode = detectedBarcode
    }
    
    // MARK: - Properties
    
    @Binding var detectedBarcode: String
    
    // MARK: - View controller representable
    
    func makeUIViewController(context: Context) -> UIViewController {
        return BarcodeScanningViewController($detectedBarcode)
    }
    
    func updateUIViewController(_ viewController: UIViewController, context: Context) {
        // The underlying view controller does not need to be updated in any way.
    }
}
