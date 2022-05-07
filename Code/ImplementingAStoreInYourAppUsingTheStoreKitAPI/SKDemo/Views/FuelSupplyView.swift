/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view showing the total supply of each type of fuel purchased.
*/

import SwiftUI
import StoreKit

enum FuelKey: String {
    case octane87 = "consumable.fuel.octane87"
    case octane89 = "consumable.fuel.octane89"
    case octane91 = "consumable.fuel.octane91"
}

struct FuelSupplyView: View {
    @EnvironmentObject var store: Store

    @AppStorage(FuelKey.octane87.rawValue) var octane87 = 0
    @AppStorage(FuelKey.octane89.rawValue) var octane89 = 0
    @AppStorage(FuelKey.octane91.rawValue) var octane91 = 0

    let fuels: [Product]
    let consumedFuel: (Product) -> Void
    
    var body: some View {
        VStack {
            Text("Power up your ride with fuel!")
            HStack(spacing: 15) {
                ForEach(fuels, id: \.id) { fuel in
                    Button(action: {
                        consume(fuel: fuel)
                        consumedFuel(fuel)
                    }) {
                        VStack {
                            let fuelAmount = amount(for: fuel)
                            let hasFuel = (fuelAmount > 0)
                            VStack {
                                Text(fuel.description)
                                    .foregroundColor(.black)
                                Text(store.emoji(for: fuel.id))
                            }
                            .clipShape(Rectangle())
                            .padding([.leading, .trailing], 15)
                            .padding([.top, .bottom], 5)
                            .background(Color.yellow)
                            .cornerRadius(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.blue, lineWidth: hasFuel ? 3 : 0)
                            )
                            Text("\(fuelAmount)")
                        }
                        
                    }
                    .disabled(amount(for: fuel) == 0)
                }
            }
        }
    }
    
    fileprivate func amount(for fuel: Product) -> Int {
        switch fuel.id {
        case FuelKey.octane87.rawValue: return octane87
        case FuelKey.octane89.rawValue: return octane89
        case FuelKey.octane91.rawValue: return octane91
        default: return 0
        }
    }

    fileprivate func consume(fuel: Product) {
        switch fuel.id {
        case FuelKey.octane87.rawValue:
            if octane87 > 0 {
                octane87 -= 1
            }
        case FuelKey.octane89.rawValue:
            if octane89 > 0 {
                octane89 -= 1
            }
        case FuelKey.octane91.rawValue:
            if octane91 > 0 {
                octane91 -= 1
            }
        default: return
        }
    }
}
