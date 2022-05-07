/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view that summarizes the smoothie and adjusts its layout based on the environment and platform.
*/

import SwiftUI

struct SmoothieHeaderView: View {
    var smoothie: Smoothie
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    var horizontallyConstrained: Bool {
        #if os(iOS)
        return horizontalSizeClass == .compact
        #else
        return false
        #endif
    }

    var body: some View {
        Group {
            if horizontallyConstrained {
                fullBleedContent
            } else {
                wideContent
            }
        }
        .accessibilityElement(children: .combine)
    }
    
    var fullBleedContent: some View {
        VStack(spacing: 0) {
            smoothie.image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .accessibility(hidden: true)
            
            VStack(alignment: .leading) {
                Text(smoothie.description)
                Text(smoothie.energy.formatted(.measurement(width: .wide, usage: .food)))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background()
        }
    }
    
    var wideClipShape = RoundedRectangle(cornerRadius: 20, style: .continuous)
    var wideContent: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                #if os(macOS)
                Text(smoothie.title)
                    .font(Font.largeTitle.bold())
                #endif
                Text(smoothie.description)
                    .font(.title2)
                Spacer()
                Text(smoothie.energy.formatted(.measurement(width: .wide, usage: .asProvided)))
                    .foregroundStyle(.secondary)
                    .font(.headline)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background()
            
            smoothie.image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 220, height: 250)
                .clipped()
                .accessibility(hidden: true)
        }
        .frame(height: 250)
        .clipShape(wideClipShape)
        .overlay {
            wideClipShape.strokeBorder(.quaternary, lineWidth: 0.5)
        }
        .padding()
    }
}

struct SmoothieHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        SmoothieHeaderView(smoothie: .berryBlue)
    }
}
