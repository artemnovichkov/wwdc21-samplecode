/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A window controller that displays the materialized and pending items for a domain.
*/

import FileProvider
import SwiftUI
import Common

// This controller provides the window for viewing items for a domain. It can be
// configured to show either the pending set or the materialized set.
class EnumerationWindowController: NSWindowController {
    init(_ domain: NSFileProviderDomain, _ which: EnumerationView.EnumerationType) {
        let size = CGSize(width: 700, height: 300)
        let rootView = EnumerationView(domain, which).frame(minWidth: size.width, minHeight: size.height, alignment: .center)
        let hosting = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hosting)
        window.minSize = size
        window.maxSize = CGSize(width: CGFloat.infinity, height: CGFloat.infinity)
        window.styleMask.update(with: [.resizable, .titled])
        window.isExcludedFromWindowsMenu = true
        switch which {
        case .materialized:
            window.title = "Materialized items for \(domain.displayName)"
        case .pending:
            window.title = "Pending items for \(domain.displayName)"
        }
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
