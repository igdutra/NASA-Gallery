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
    
    func configure(with image: ImageResource, contentMode: UIView.ContentMode) {
        imageView.image = UIImage(resource: image)
        imageView.contentMode = contentMode
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
            switch sectionIndex {
            case 0:
                return self.createBigRowLayout(for: UIImage(resource: .apod1))
            case 1:
                return self.createHorizontalRowLayout()
            case 2:
                return self.createColumnLayout()
            default:
                return nil
            }
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
            
            let contentMode: UIView.ContentMode
            switch indexPath.section {
            case 0:
                contentMode = .scaleAspectFit
            default:
                contentMode = .scaleAspectFill
            }
            
            cell.configure(with: imageResource, contentMode: contentMode)
            
            return cell
        }
    }
    
    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, ImageResource>()
        snapshot.appendSections([0, 1, 2])
        
//        snapshot.appendItems([.apod1], toSection: 0) // Big row
//        snapshot.appendItems([.apod11, .apod12, .apod4, .apod5, .apod6, .apod7, .apod8], toSection: 1) // Horizontal row
        snapshot.appendItems([.apod2, .apod3, .apod9, .apod10, .apod13, .apod14, .apod15], toSection: 2) // Column row
        
        dataSource.apply(snapshot, animatingDifferences: true)
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
    
    private func createColumnLayout() -> NSCollectionLayoutSection {
//        let widthScale = UIScreen.main.bounds.width / image.size.width

        // Item will take the total available space by the group
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        // Group will take full width and
        // the height WILL be the scaled height image.
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .fractionalHeight(1))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        return section
    }
    
    private func createHorizontalRowLayout() -> NSCollectionLayoutSection {
        let spacing: CGFloat = 4  // Adjust for spacing
        
        // 📌 First row (Two images: 2.5/5 + 2.5/5)
        let firstItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(2.5 / 5),
                                                   heightDimension: .fractionalHeight(1))
        let firstItem = NSCollectionLayoutItem(layoutSize: firstItemSize)
        firstItem.contentInsets = NSDirectionalEdgeInsets(top: spacing, leading: spacing, bottom: spacing, trailing: spacing)
        
        let secondItem = NSCollectionLayoutItem(layoutSize: firstItemSize)
        secondItem.contentInsets = NSDirectionalEdgeInsets(top: spacing, leading: spacing, bottom: spacing, trailing: spacing)
        
        let firstRow = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .fractionalHeight(1/3)), // 1/3 of section height,
            subitems: [firstItem, secondItem]
        )
        
        // 📌 Second row (Three images: 1/5 + 3/5 + 1/5)
        let smallItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0 / 5),
                                                   heightDimension: .fractionalHeight(0.4))
        let largeItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(3.0 / 5),
                                                   heightDimension: .fractionalHeight(1.0))
        
        let smallItem1 = NSCollectionLayoutItem(layoutSize: smallItemSize)
        smallItem1.contentInsets = NSDirectionalEdgeInsets(top: spacing, leading: spacing, bottom: spacing, trailing: spacing)
        
        let largeItem = NSCollectionLayoutItem(layoutSize: largeItemSize)
        largeItem.contentInsets = NSDirectionalEdgeInsets(top: spacing, leading: spacing, bottom: spacing, trailing: spacing)
        
        let smallItem2 = NSCollectionLayoutItem(layoutSize: smallItemSize)
        smallItem2.contentInsets = NSDirectionalEdgeInsets(top: spacing, leading: spacing, bottom: spacing, trailing: spacing)
        // Note: how to pin the 3 row images
        smallItem2.edgeSpacing = NSCollectionLayoutEdgeSpacing(leading: nil,
                                                               top: .flexible(1),
                                                               trailing: nil,
                                                               bottom: nil)
        
        let secondRow = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .fractionalHeight(1/3)),
            subitems: [smallItem1, largeItem, smallItem2]
        )
        
        // 📌 Third row (Two images: 4/5 + 1/5)
        let wideItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(4.0 / 5),
                                                  heightDimension: .fractionalHeight(1.0))
        let wideItem = NSCollectionLayoutItem(layoutSize: wideItemSize)
        wideItem.contentInsets = NSDirectionalEdgeInsets(top: spacing, leading: spacing, bottom: spacing, trailing: spacing)
        
        let smallTallItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0 / 5),
                                                       heightDimension: .fractionalHeight(0.6))
        let smallTallItem = NSCollectionLayoutItem(layoutSize: smallTallItemSize)
        smallTallItem.contentInsets = NSDirectionalEdgeInsets(top: spacing, leading: spacing, bottom: spacing, trailing: spacing)
        smallTallItem.edgeSpacing = NSCollectionLayoutEdgeSpacing(leading: nil,
                                                                  top: .flexible(1),
                                                                  trailing: nil,
                                                                  bottom: .flexible(1))
        
        let thirdRow = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .fractionalHeight(1/3)),
            subitems: [wideItem, smallTallItem]
        )
        
        // 📌 Stack rows vertically
        let fullSection = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .fractionalHeight(0.8)), // Dynamically adjusts),
            subitems: [firstRow, secondRow, thirdRow]
        )

        return NSCollectionLayoutSection(group: fullSection)
    }

}

// MARK: - Preview

#Preview {
    APODGalleryViewController()
}
