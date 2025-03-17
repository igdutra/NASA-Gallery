//
//  UIKitView.swift
//  Prototype
//
//  Created by Ivo on 25/02/25.
//

import UIKit
import DeveloperToolsSupport

// MARK: - CELL

final class APODImageCell: UICollectionViewCell {
    
    static let reuseIdentifier = "APODImageCell"
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) { nil }
    
    func configure(with image: ImageResource) {
        imageView.image = UIImage(resource: .apod1)
        // Useful for debugging
//        contentView.backgroundColor = .red
    }
}

// MARK: - CONTROLLER

final class APODGalleryViewController: UIViewController {
    
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, ImageResource>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupCollectionView()
        setupDataSource()
        applySnapshot()
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment in
            return self.createBigRowLayout(for: UIImage(resource: .apod1))
        }
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .black
        collectionView.register(APODImageCell.self, forCellWithReuseIdentifier: APODImageCell.reuseIdentifier)
        
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, ImageResource>(collectionView: collectionView) { (collectionView, indexPath, imageResource) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: APODImageCell.reuseIdentifier, for: indexPath) as! APODImageCell
            cell.configure(with: imageResource)
            return cell
        }
    }
    
    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, ImageResource>()
        snapshot.appendSections([0])
        snapshot.appendItems([.apod1]) // Using apod1 as the image
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
//    Items: Smallest unit, represents a single cell.
//    Groups: Containers that hold multiple items.
//    Sections: Containers that hold multiple groups.
    private func createBigRowLayout(for image: UIImage) -> NSCollectionLayoutSection {
        let widthScale = UIScreen.main.bounds.width / image.size.width

        // Item will take the total available space by the group
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        // Group will take full width and
        // the height WILL be the scaled height image.
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(image.size.height * widthScale))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        return section
    }
}

// MARK: - Preview

#Preview {
    APODGalleryViewController()
}
