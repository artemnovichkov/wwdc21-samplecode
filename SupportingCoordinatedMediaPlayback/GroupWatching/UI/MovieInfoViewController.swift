/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that displays movie details in the iPad app.
*/

import UIKit
import Combine

class MovieInfoViewController: UIViewController {
    
    private var movieCancellable: AnyCancellable?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        movieCancellable = CoordinationManager.shared.$enqueuedMovie
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] movie in
                self?.titleLabel.text = movie.title
                self?.textView.text = movie.description
            }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.preferredFont(forTextStyle: .title2)
        
        label.textColor = UIColor(white: 0.95, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var textView: UITextView = {
        let textView = UITextView(frame: .zero)
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.textColor = UIColor(white: 0.7, alpha: 1.0)
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isSelectable = false
        textView.contentInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, textView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
