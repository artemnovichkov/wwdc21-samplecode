/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An image view subclass that loads poster images for the app's media.
*/

import UIKit
import AVFoundation

class PosterImageView: UIImageView {
    
    private var poster: Poster?
    
    init() {
        super.init(frame: .zero)
        backgroundColor = .black
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var movie: Movie? {
        didSet {
            updateImage(image: nil)
            guard let movie = movie else { return }
            poster = Poster(url: movie.url, posterTime: movie.posterTime)
            poster!.loadImage { [weak self] image in
                self?.updateImage(image: image)
            }
        }
    }
    
    private func updateImage(image: UIImage?) {
        DispatchQueue.main.async {
            self.image = image
        }
    }
}
