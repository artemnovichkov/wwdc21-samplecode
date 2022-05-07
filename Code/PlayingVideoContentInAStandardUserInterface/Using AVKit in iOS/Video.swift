/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Video is a simple struct that provides the title, url, and timing information about the app's videos.
*/

import UIKit
import AVFoundation

struct Video: Hashable {
    
    let hlsUrl: URL
    let title: String
    let duration: TimeInterval
    var resumeTime: TimeInterval
    
    init(hlsUrl: URL, title: String, duration: TimeInterval, resumeTime: TimeInterval = 0) {
        self.hlsUrl = hlsUrl
        self.title = title
        self.duration = duration
        self.resumeTime = resumeTime
    }
}

extension Video {
    
    static func makeVideos() -> [Video] {
        return [
            Video(hlsUrl: URL(string: "https://devstreaming-cdn.apple.com/videos/wwdc/2018/103zvtnsrnrijr/103/hls_vod_mvp.m3u8")!,
                  title: "Apple Design Awards",
                  duration: 2946),
            Video(hlsUrl: URL(string: "https://devstreaming-cdn.apple.com/videos/wwdc/2018/225s90wcvt1fjg6b/225/hls_vod_mvp.m3u8")!,
                  title: "A Tour of UICollectionView",
                  duration: 2422),
            Video(hlsUrl: URL(string: "https://p-events-delivery.akamaized.net/18oijbasfvuhbfsdvoijhbsdfvljkb6/m3u8/hls_vod_mvp.m3u8")!,
                  title: "WWDC 2018 Keynote",
                  duration: 8181),
            Video(hlsUrl: URL(string: "https://devstreaming-cdn.apple.com/videos/wwdc/2018/803lpnlacvg2jsndx/803/hls_vod_mvp.m3u8")!,
                  title: "Designing Fluid Interfaces",
                  duration: 3881),
            Video(hlsUrl: URL(string: "https://devstreaming-cdn.apple.com/videos/wwdc/2018/805llmiw0zwkox4zhuc/805/hls_vod_mvp.m3u8")!,
                  title: "Creating Great AR Experiences",
                  duration: 3757),
            Video(hlsUrl: URL(string: "https://devstreaming-cdn.apple.com/videos/wwdc/2018/102ly3xmvz1ssb1ill/102/hls_vod_mvp.m3u8")!,
                  title: "Platforms State of the Union",
                  duration: 5654),
            Video(hlsUrl: URL(string: "https://devstreaming-cdn.apple.com/videos/wwdc/2018/507axjplrd0yjzixfz/507/hls_vod_mvp.m3u8")!,
                  title: "AVContentKeySession Best Practices",
                  duration: 923),
            Video(hlsUrl: URL(string: "https://devstreaming-cdn.apple.com/videos/wwdc/2018/808j4pqwu6uymymjq/808/hls_vod_mvp.m3u8")!,
                  title: "Prototyping for AR",
                  duration: 638),
            Video(hlsUrl: URL(string: "https://devstreaming-cdn.apple.com/videos/wwdc/2018/208piymryv9im6/208/hls_vod_mvp.m3u8")!,
                  title: "What's New in tvOS 12",
                  duration: 2374),
            Video(hlsUrl: URL(string: "https://devstreaming-cdn.apple.com/videos/wwdc/2018/502plwzfxg5p7w4na/502/hls_vod_mvp.m3u8")!,
                  title: "Measuring and Optimizing HLS Performance",
                  duration: 2972),
            Video(hlsUrl: URL(string: "https://devstreaming-cdn.apple.com/videos/wwdc/2017/219okz4tp7uyw5n/219/hls_vod_mvp.m3u8")!,
                  title: "Modern User Interaction on iOS",
                  duration: 2178),
            Video(hlsUrl: URL(string: "https://devstreaming-cdn.apple.com/videos/wwdc/2017/515vy4sl7iu70/515/hls_vod_mvp.m3u8")!,
                  title: "HLS Authoring Update",
                  duration: 547),
            Video(hlsUrl: URL(string: "https://p-events-delivery.akamaized.net/17qopibbefvoiuhbsefvbsefvopihb06/m3u8/hls_vod_mvp.m3u8")!,
                  title: "WWDC 2017 Keynote",
                  duration: 8345),
            Video(hlsUrl: URL(string: "https://devstreaming-cdn.apple.com/videos/wwdc/2017/102xyar2647hak3e/102/hls_vod_mvp.m3u8")!,
                  title: "Platforms State of the Union",
                  duration: 6191),
            Video(hlsUrl: URL(string: "https://devstreaming-cdn.apple.com/videos/wwdc/2017/251txgutnwpkc4740f/251/hls_vod_mvp.m3u8")!,
                  title: "Now Playing and Remote Commands on tvOS",
                  duration: 881)
        ]
    }
}
