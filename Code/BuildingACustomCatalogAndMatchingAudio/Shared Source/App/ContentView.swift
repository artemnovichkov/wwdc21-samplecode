/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main UI that changes views depending on the state of the match.
*/

import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject var matcher: Matcher
    
    var body: some View {
        ZStack {
            // Show available episodes, before we begin.
            EpisodeListView(currentEpisode: nil)
            
            if let question = matcher.result.question {
                // Show the content of the episode when we found a Question.
                EpisodeView(question: question)
            } else if let mediaItem = matcher.result.mediaItem {
                // Show episode list view when we have a match, but no content found yet.
                EpisodeListView(currentEpisode: Episode.allEpisodes.first { episode in
                    episode.number == mediaItem.episode
                })
            }
        }.onAppear {
            do {
                if let catalog = try CatalogProvider.catalog() {
                    try matcher.match(catalog: catalog)
                }
            } catch {
                print(error)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Matcher())
            .previewInterfaceOrientation(.landscapeRight)
    }
}
