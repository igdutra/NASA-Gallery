//
//  GalleryViewController.swift
//  NASAGalleryiOS
//
//  Created by Ivo on 11/09/25.
//

import Foundation
import NASAGallery
import UIKit

public final class GalleryViewController: UICollectionViewController {
    private var loader: GalleryLoader?
    private var imageLoader: GalleryImageDataLoader?
    private var onViewIsAppearing: ((GalleryViewController) -> Void)?

    private enum Section {
        case main
    }

    private var dataSource: UICollectionViewDiffableDataSource<Section, GalleryImage>?
    private var gallery: [GalleryImage] = []
    private var imageLoadingTasks: [IndexPath: GalleryImageDataLoaderTask] = [:]

    public convenience init(loader: GalleryLoader, imageLoader: GalleryImageDataLoader? = nil) {
        self.init(collectionViewLayout: Self.makeLayout())
        self.loader = loader
        self.imageLoader = imageLoader
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.delegate = self
        collectionView.prefetchDataSource = self

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(load), for: .valueChanged)
        self.collectionView.refreshControl = refreshControl

        setupCollectionView()
        setupDataSource()

        onViewIsAppearing = { vc in
            // Author note: not ideal, moving forward for now.
            vc.load()
            vc.onViewIsAppearing = nil
        }
    }
    
    public override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        
        onViewIsAppearing?(self)
    }
    
    // MARK: - Layout
    
    private func setupCollectionView() {
    }
    
    // MARK: - Datasource
    
    private func setupDataSource() {
        let registration = UICollectionView.CellRegistration<GalleryImageCell, GalleryImage> { cell, _, model in
            cell.apply(model: model)
        }

        dataSource = UICollectionViewDiffableDataSource<Section, GalleryImage>(collectionView: collectionView) { collectionView, indexPath, galleryImage in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: galleryImage)
        }

        var snapshot = NSDiffableDataSourceSnapshot<Section, GalleryImage>()
        snapshot.appendSections([.main])
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
    
    @MainActor
    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, GalleryImage>()
        snapshot.appendSections([.main])
        snapshot.appendItems(gallery, toSection: .main)
        dataSource?.applySnapshotUsingReloadData(snapshot)
    }
    
    // MARK: - Load
    
    @objc
    private func load() {
        collectionView.refreshControl?.beginRefreshing()

        Task { @MainActor in
            defer { self.collectionView.refreshControl?.endRefreshing() }
            
            do {
                if let gallery = try await loader?.load() {
                    self.gallery = gallery
                    applySnapshot()
                }
            } catch {
                
            }
        }
    }

    // MARK: - UICollectionViewDelegate

    public override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? GalleryImageCell,
              let imageLoader = imageLoader,
              indexPath.row < gallery.count else { return }

        let galleryImage = gallery[indexPath.row]

        // Check if we already have a task (from prefetch or previous load)
        let task: GalleryImageDataLoaderTask
        if let existingTask = imageLoadingTasks[indexPath] {
            // REUSE the existing task! Prefetch work isn't wasted!
            task = existingTask
        } else {
            // Create new task only if needed
            task = imageLoader.loadImageData(from: galleryImage.url)
            imageLoadingTasks[indexPath] = task
        }

        cell.startLoading()

        Task { @MainActor in
            do {
                let data = try await task.value
                if let image = UIImage(data: data) {
                    cell.display(image)
                }
                cell.stopLoading()
            } catch {
                cell.stopLoading()
                cell.showRetry()
            }
        }
    }

    public override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        imageLoadingTasks[indexPath]?.cancel()
        imageLoadingTasks[indexPath] = nil
    }
}

// MARK: - Layout

private extension GalleryViewController {
    static func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { sectionIndex, environment in
            // Create a full-width item with automatic height
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(300)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(300)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 16
            section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0)

            return section
        }
    }
}

// MARK: - UICollectionViewDataSourcePrefetching

extension GalleryViewController: UICollectionViewDataSourcePrefetching {
    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        guard let imageLoader = imageLoader else { return }

        for indexPath in indexPaths {
            guard indexPath.row < gallery.count else { continue }
            guard imageLoadingTasks[indexPath] == nil else { continue }

            let galleryImage = gallery[indexPath.row]
            let task = imageLoader.loadImageData(from: galleryImage.url)
            imageLoadingTasks[indexPath] = task

            // Start loading in background - no UI to update since cell isn't visible yet
            Task { @MainActor in
                do {
                    _ = try await task.value
                    // Image is now cached/loaded, ready for when cell appears
                } catch {
                    // Prefetch errors are silently ignored - will retry when cell appears
                }
            }
        }
    }
}
