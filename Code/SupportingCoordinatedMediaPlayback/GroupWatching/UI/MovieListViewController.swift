/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A list-based collection view that presents a list of movies to play.
*/

import UIKit
import Combine

class MovieListViewController: UIViewController {
    
    private var subscriptions = Set<AnyCancellable>()
    
    private let movies = Library.shared.movies
    
    private var selectedMovie: Movie? {
        didSet {
            // Ensure the UI selection always represents the currently playing media.
            guard let movie = selectedMovie,
                  let indexPathOfCurrentSelection = collectionView.indexPathsForSelectedItems?.first,
                  let indexOfSelectedMovie = movies.firstIndex(where: { $0 == movie }),
                  indexPathOfCurrentSelection.row != indexOfSelectedMovie else { return }
            
            // If the currently selected row in the collection view doesn't match
            // the current media, programmatically update the selection state.
            selectRow(at: indexOfSelectedMovie)
        }
    }
    
    var backgroundColor: UIColor {
        let isCompact = traitCollection.horizontalSizeClass == .compact || traitCollection.verticalSizeClass == .compact
        return isCompact ? .contentBackground : .baseBackground
    }
    
    private var collectionView: UICollectionView = {
        var config = UICollectionLayoutListConfiguration(appearance: .plain)
        config.backgroundColor = .baseBackground
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()
    
    private var dataSource: UICollectionViewDiffableDataSource<Section, Movie>!
    
    enum Section {
        case main
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        title = "Movies"
        
        // The movie subscriber.
        CoordinationManager.shared.$enqueuedMovie
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .assign(to: \.selectedMovie, on: self)
            .store(in: &subscriptions)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        collectionView.pinToSuperviewEdges()
        configureDataSource()
        
        view.backgroundColor = backgroundColor
        collectionView.backgroundColor = backgroundColor
        selectRow(at: 0)
    }
    
    func selectRow(at row: Int) {
        // Set the default selection.
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: row, section: 0)
            self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .top)
        }
    }
    
    private func configureDataSource() {
        let registration = UICollectionView.CellRegistration<MovieListCell, Movie> { cell, indexPath, movie in
            var configuration = cell.defaultContentConfiguration()
            
            configuration.text = movie.title
            configuration.textProperties.color = .init(white: 0.95, alpha: 1.0)
            
            configuration.secondaryText = movie.description
            configuration.secondaryTextProperties.numberOfLines = 3
            configuration.secondaryTextProperties.color = .systemGray
            
            cell.contentConfiguration = configuration
            
            cell.backgroundConfiguration?.backgroundColor = .baseBackground
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, Movie>(collectionView: collectionView) { collectionView, indexPath, identifier in
            return collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: identifier)
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Movie>()
        snapshot.appendSections([.main])
        snapshot.appendItems(movies)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

extension MovieListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Prepare to play the selected movie.
        CoordinationManager.shared.prepareToPlay(movies[indexPath.row])
    }
}

class MovieListCell: UICollectionViewListCell {
    override func updateConfiguration(using state: UICellConfigurationState) {
        backgroundConfiguration = MovieListBackgroundConfiguration.configuration(for: state)
    }
}

struct MovieListBackgroundConfiguration {
    static func configuration(for state: UICellConfigurationState) -> UIBackgroundConfiguration {
        var background = UIBackgroundConfiguration.listPlainCell()
        if state.isHighlighted {
            background.backgroundColor = .highlightedBackground
        } else if state.isSelected {
            background.backgroundColor = .selectedBackground
        } else {
            background.backgroundColor = .baseBackground
        }
        return background
    }
}
