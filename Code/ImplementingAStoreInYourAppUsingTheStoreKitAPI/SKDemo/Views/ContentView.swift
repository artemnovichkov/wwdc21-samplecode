/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main view of the app.
*/

import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @StateObject var store: Store = Store()
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Demo App")
                    .bold()
                    .font(.system(size: sizeClass == .compact ? 50 : 40))
                    .padding(.bottom, sizeClass == .compact ? 20 : 5)
                VStack(spacing: 10) {
                    Text("🏎💨")
                        .font(.system(size: 120))
                        .padding(.bottom, 20)
                    myCarsLink
                    shopLink
                }
            }
        }
        .environmentObject(store)
    }
    
    var shopLink: some View {
        let shopView = StoreView()
        return NavigationLink(destination: shopView) {
            Text("\(Image(systemName: "cart")) Shop")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(width: 300, height: sizeClass == .compact ? 50 : 40)
                .background(Color.blue)
                .cornerRadius(15.0)
        }
    }
    
    var myCarsLink: some View {
        let shopView = MyCarsView()
        return NavigationLink(destination: shopView) {
            Text("\(Image(systemName: "car")) My Cars")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(width: 300, height: sizeClass == .compact ? 50 : 40)
                .background(Color.blue)
                .cornerRadius(15.0)
        }
    }
}
