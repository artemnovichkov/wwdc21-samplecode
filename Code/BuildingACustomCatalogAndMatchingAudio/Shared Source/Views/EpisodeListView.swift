/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view model that shows a list of episodes at the start.
*/

import SwiftUI

struct EpisodeListView: View {
    let currentEpisode: Episode?
    
    var body: some View {
        ZStack {
            BackgroundView()
            EpisodeList()
                .frame(width: 720, height: 666)
            if let episode = currentEpisode {
                CardView(title: episode.title, subtitle: episode.subtitle, image: .threeApplesImage)
            }
        }.shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 10)
    }
}

private struct EpisodeList: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            Text("Episodes")
                .foregroundColor(.customTitleColor)
                .font(.system(size: 60, weight: .black, design: .rounded))
            ScrollView {
                ForEach(Episode.allEpisodes, id: \.id) { episode in
                    EpisodeCell(episode: episode)
                }
            }
        }
        .padding([.leading, .trailing], 80)
        .padding(.top, 64)
        .background(Color.white)
        .cornerRadius(24)
    }
}

private struct EpisodeCell: View {
    let episode: Episode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("EPISODE \(episode.number)")
                .foregroundColor(.customSubtitleColor)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .opacity(0.6)
                .padding(.top, 13)
                .padding(.leading, 5)
            Text(episode.title)
                .foregroundColor(.customSubtitleColor)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .padding(.bottom, 6)
                .padding(.leading, 5)
            Divider()
        }
    }
}

private struct BackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient.backgroundGradient(startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            Image.bigAppleImage
                .position(x: 170, y: 150)
            Image.bigAppleImage
                .position(x: 987, y: 600)
            Image.smallGreenAppleImage
                .position(x: 220, y: 756)
            Image.smallGreenAppleImage
                .position(x: 1150, y: 127)
        }
    }
}

struct EpisodeListView_Previews: PreviewProvider {
    static var previews: some View {
        EpisodeListView(currentEpisode: nil)
            .previewInterfaceOrientation(.landscapeRight)
    }
}
