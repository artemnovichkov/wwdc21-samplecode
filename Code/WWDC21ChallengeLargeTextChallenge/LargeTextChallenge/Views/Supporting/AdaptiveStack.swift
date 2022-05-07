/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Helper stack view which updates the content inside to a VStack, or HStack,
 based on the supplied Binding.
*/

import SwiftUI

// Constructs a Stack that can update the content to a HStack or VStack, based
// on the supplied Binding. This allows for content that doesn't scale well
// horizontally with larger text sizes to instead stack vertically. This
// also works with smaller text sizes, where there's enough space onscreen
// to lay out the content horizontally.

struct AdaptiveStack<Content: View>: View {
    // Binding that tracks if the content is vertical.
    @Binding var isVertical: Bool
    
    // The alignment when the content is in a VStack.
    let horizontalAlignment: HorizontalAlignment
    // The alignment when the content is in a HStack.
    let verticalAlignment: VerticalAlignment
    // The content to update when the stack should be changed.
    let content: () -> Content

    // Initialize the Stack with a Binding that returns a Bool value. This
    // value indicates if the content should be in a VStack or HStack.
    init(isVertical: Binding<Bool>,
         horizontalAlignment: HorizontalAlignment = .center,
         verticalAlignment: VerticalAlignment = .center,
         spacing: CGFloat? = nil,
         @ViewBuilder content: @escaping
           () -> Content) {
        
        self._isVertical = isVertical
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.content = content
    }

    var body: some View {
        Group {
            if isVertical {
                VStack(alignment: horizontalAlignment, content: content)
            } else {
                HStack(alignment: verticalAlignment, content: content)
            }
        }
    }
}
