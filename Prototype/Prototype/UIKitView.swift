//
//  UIKitView.swift
//  Prototype
//
//  Created by Ivo on 25/02/25.
//

import UIKit
import DeveloperToolsSupport

// MARK: - CELL

// Author note: need to revist this.
// Apperently there's a difference calling UIAnimate inside a HostingController (maybe)
// Check runloops
// And new chatGPT shimmer effect does not move.

final class APODImageCell: UICollectionViewCell {
    
    static let reuseIdentifier = "APODImageCell"
    
    private let imageViewContainer: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.alpha = 0
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageViewContainer)
        imageViewContainer.addSubview(imageView)
        
        imageView.image = nil
        imageView.alpha = 0
        
        NSLayoutConstraint.activate([
            imageViewContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageViewContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageViewContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageViewContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            imageView.topAnchor.constraint(equalTo: imageViewContainer.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: imageViewContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: imageViewContainer.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageViewContainer.bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) { nil }
    
    func configure(with image: ImageResource, contentMode: UIView.ContentMode) {
        imageView.contentMode = contentMode
        fadeIn(UIImage(resource: image))
    }
    
    private var hasStartedShimmering = false

    override func layoutSubviews() {
        super.layoutSubviews()

        // This guarantees bounds are valid and avoids duplicate shimmers
        if !hasStartedShimmering, window != nil {
            hasStartedShimmering = true
            imageViewContainer.startShimmering()
        }
    }
    
    private func fadeIn(_ image: UIImage?) {
        imageView.image = image
        // Note: this print proved the completion block was being invoked right afterwards.
        // Without the DispatchQueue.main, this is what happens:
//        started 2025-04-15 23:18:02 +0000
//        completed at 2025-04-15 23:18:03 +0000
//        print("started", Date())

        // Dispatching to main ensures UIKit layout is done, avoiding skipped animations
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            UIView.animate(withDuration: 3,
                           delay: 1.5,
                           options: [],
                           animations: {
                self.imageView.alpha = 1
            }, completion: { completed in
                if completed {
//                    print("completed at", Date())
                    self.imageViewContainer.stopShimmering()
                }
            })
        }
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()

        guard window != nil else { return }

        // Ensures shimmer only starts once the view is attached to window (critical in SwiftUI embedding)
        imageViewContainer.startShimmering()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        imageView.alpha = 0
        imageViewContainer.startShimmering()
        hasStartedShimmering = false // ✅ reset shimmer state so it will start again on reuse
    }
}

// MARK: - CONTROLLER

// Note: Do it with native UICollectionViewController (the refreshcontrol should be for free)
final class APODGalleryViewController: UIViewController {
    
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, ImageResource>!
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .white
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupCollectionView()
        setUpRefresh()
        setupDataSource()
        applySnapshot()
    }
    
    private func setUpRefresh() {
        refreshControl.backgroundColor = .white
        refreshControl.addTarget(self, action: #selector(didPullToRefresh(_:)), for: .valueChanged)
        collectionView.alwaysBounceVertical = true
        collectionView.refreshControl = refreshControl
        collectionView.refreshControl?.backgroundColor = .black
    }
    
    @objc
    private func didPullToRefresh(_ sender: Any) {
        refreshControl.beginRefreshing()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.applySnapshot()
            self.refreshControl.endRefreshing()
        }
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
        
        snapshot.appendItems([.apod1], toSection: 0) // Big row
        snapshot.appendItems([.apod11, .apod12, .apod4, .apod5, .apod6, .apod7, .apod8], toSection: 1) // Horizontal row
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
        let spacing: CGFloat = 4
        // First Column
        let firstColumnItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                         heightDimension: .fractionalHeight(1/5))
        let firstColumnItem = NSCollectionLayoutItem(layoutSize: firstColumnItemSize)
        firstColumnItem.contentInsets = NSDirectionalEdgeInsets(top: spacing, leading: spacing, bottom: spacing, trailing: spacing)
        let firstColumnGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/2),
                                                          heightDimension: .fractionalHeight(1))
        let firstColumnGroup = NSCollectionLayoutGroup.vertical(layoutSize: firstColumnGroupSize,
                                                                repeatingSubitem: firstColumnItem,
                                                                count: 5)
        // Second Column
        let secondColumnItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                          heightDimension: .fractionalHeight(1/2))
        let secondColumnItem = NSCollectionLayoutItem(layoutSize: secondColumnItemSize)
        secondColumnItem.contentInsets = NSDirectionalEdgeInsets(top: spacing, leading: spacing, bottom: spacing, trailing: spacing)
        let secondColumnGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/2),
                                                           heightDimension: .fractionalHeight(1))
        let secondColumnGroup = NSCollectionLayoutGroup.vertical(layoutSize: secondColumnGroupSize,
                                                                 repeatingSubitem: secondColumnItem,
                                                                 count: 2)
        
        // 📌 Stack rows horizontally
        let fullSection = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .fractionalHeight(1.0)),
            subitems: [firstColumnGroup, secondColumnGroup]
        )
        
        return NSCollectionLayoutSection(group: fullSection)
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
