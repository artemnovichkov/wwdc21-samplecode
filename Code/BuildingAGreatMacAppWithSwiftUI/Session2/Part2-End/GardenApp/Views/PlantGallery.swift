/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The plant gallery view.
*/

import SwiftUI
import Foundation

struct PlantGallery: View {
    @State private var itemSize: CGFloat = 250
    @Binding var garden: Garden
    @Binding var selection: Set<Plant.ID>

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 40) {
                ForEach(garden.plants) {
                    GalleryItem(plant: $0, size: itemSize, selection: $selection)
                }
            }
        }
        .padding([.horizontal, .top])
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ItemSizeSlider(size: $itemSize)
        }
        .onTapGesture {
            selection = []
        }
    }

    var columns: [GridItem] {
        [GridItem(.adaptive(minimum: itemSize, maximum: itemSize), spacing: 40)]
    }

    private struct GalleryItem: View {
        var plant: Plant
        var size: CGFloat
        @Binding var selection: Set<Plant.ID>

        var body: some View {
            VStack {
                GalleryImage(plant: plant, size: size)
                    .background(selectionBackground)
                Text(verbatim: plant.variety)
                    .font(.callout)
            }
            .frame(width: size)
            .onTapGesture {
                selection = [plant.id]
            }
        }

        var isSelected: Bool {
            selection.contains(plant.id)
        }

        @ViewBuilder
        var selectionBackground: some View {
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.selection)
            }
        }
    }

    private struct GalleryImage: View {
        var plant: Plant
        var size: CGFloat

        var body: some View {
            AsyncImage(url: plant.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .background(background)
                    .frame(width: size, height: size)
            } placeholder: {
                Image(systemName: "leaf")
                    .symbolVariant(.fill)
                    .font(.system(size: 40))
                    .foregroundColor(Color.green)
                    .background(background)
                    .frame(width: size, height: size)
            }
        }

        var background: some View {
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
                .frame(width: size, height: size)
        }
    }

    private struct ItemSizeSlider: View {
        @Binding var size: CGFloat

        var body: some View {
            HStack {
                Spacer()
                Slider(value: $size, in: 100...500)
                    .controlSize(.small)
                    .frame(width: 100)
                    .padding(.trailing)
            }
            .frame(maxWidth: .infinity)
            .background(.bar)
        }
    }
}
