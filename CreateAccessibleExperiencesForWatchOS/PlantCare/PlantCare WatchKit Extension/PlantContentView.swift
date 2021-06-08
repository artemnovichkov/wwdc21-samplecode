/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The plant content view.
*/

import SwiftUI

struct PlantContentView: View {
    @EnvironmentObject var plantData: PlantData
        
    var body: some View {
        List {
            ForEach(plantData.plants) { plant in
                PlantCellView(plant: plant)
                    .environmentObject(plantData)
            }
        }
        .navigationBarTitle(Text("Plants"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Previews

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        PlantContentView()
            .environmentObject(PlantData.shared)
    }
}
