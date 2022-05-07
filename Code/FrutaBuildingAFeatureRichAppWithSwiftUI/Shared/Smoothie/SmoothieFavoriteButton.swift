/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A button to favorite a smoothie, can be placed in a toolbar.
*/

import SwiftUI

struct SmoothieFavoriteButton: View {
    @EnvironmentObject private var model: Model
    
    var smoothie: Smoothie?
    
    var isFavorite: Bool {
        guard let smoothie = smoothie else { return false }
        return model.favoriteSmoothieIDs.contains(smoothie.id)
    }
    
    var body: some View {
        Button(action: toggleFavorite) {
            if isFavorite {
                Label {
                    Text("Remove from Favorites", comment: "Toolbar button/menu item to remove a smoothie from favorites")
                } icon: {
                    Image(systemName: "heart.fill")
                }
            } else {
                Label {
                    Text("Add to Favorites", comment: "Toolbar button/menu item to add a smoothie to favorites")
                } icon: {
                    Image(systemName: "heart")
                }

            }
        }
    }
    
    func toggleFavorite() {
        guard let smoothie = smoothie else { return }
        model.toggleFavorite(smoothie: smoothie)
    }
}

struct SmoothieFavoriteButton_Previews: PreviewProvider {
    static var previews: some View {
        SmoothieFavoriteButton(smoothie: .berryBlue)
            .padding()
            .previewLayout(.sizeThatFits)
            .environmentObject(Model())
    }
}
