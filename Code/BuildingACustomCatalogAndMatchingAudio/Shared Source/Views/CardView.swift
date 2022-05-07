/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view model for showing pop up card.
*/

import SwiftUI

struct CardView: View {
    let title: String
    let subtitle: String
    let image: Image
    let showBlur: Bool
    @Binding var visible: Bool
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            if showBlur {
                VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
                    .ignoresSafeArea()
                    .onTapGesture {
                        visible = false
                    }
            }
            VStack {
                image
                    .padding([.leading, .trailing], 90)
                    .padding(.bottom, 30)
                    .padding(.top, 45)
                Text(title)
                    .foregroundColor(.customTitleColor)
                    .font(.system(size: 60, weight: .black, design: .rounded))
                    .padding(.bottom, 15)
                    .padding([.leading, .trailing], 90)
                Text(subtitle)
                    .foregroundColor(.customSubtitleColor)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .padding([.leading, .trailing], 90)
                    .padding(.bottom, 95)
            }
                .background(Color.white)
                .cornerRadius(24)
                .scaleEffect(isAnimating ? 1 : 0.5)
                .animation(.spring(), value: isAnimating)
        }.onAppear { isAnimating.toggle() }
        .onDisappear { visible = false }
    }
}

extension CardView {
    init(title: String, subtitle: String, image: Image, visible: Binding<Bool> = .constant(false)) {
        self.title = title
        self.subtitle = subtitle
        self.image = image
        self.showBlur = true
        _visible = visible
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView(title: "Count on Me",
                 subtitle: "Episode 3",
                 image: .awardImage).previewInterfaceOrientation(.landscapeRight)
    }
}
