//
//  GalleryViewController.swift
//  NASAGalleryiOS
//
//  Created by Ivo on 11/09/25.
//

import Foundation
import NASAGallery
import UIKit

//https://www.donnywals.com/using-swifts-async-await-to-build-an-image-loader/
//
//BELEZA MEUS CUMPADRES TAMO NO JOGO! VAMO SIMBORA.
//
//agora proximo passo: eu tenho aque implementar, TUDO kkkk
//
//implementar que a célula tá visivel
//
//-> pra isso tenho que fazer o datasource, passar o datasource pra CELULA
//
//E IMPLEMENTAR O FETCH IMAGE LOADER
//
//https://www.donnywals.com/using-swifts-async-await-to-build-an-image-loader/
//


public final class GalleryViewController: UICollectionViewController {
    private var loader: GalleryLoader?
    private var onViewIsAppearing: ((GalleryViewController) -> Void)?
    
    private enum Section {
        case main
    }
    
    private var dataSource: UICollectionViewDiffableDataSource<Section, GalleryImage>?
    private var gallery: [GalleryImage] = []
    
    public convenience init(loader: GalleryLoader) {
        self.init(collectionViewLayout: Self.makeLayout())
        self.loader = loader
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        
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
    
    static let reuseIdentifier = "GalleryCell"
    
    private func setupCollectionView() {
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: Self.reuseIdentifier)
    }
    
    // MARK: - Datasource
    
    private func setupDataSource() {
        let registration = UICollectionView.CellRegistration<UICollectionViewListCell, GalleryImage> { cell, _, model in
            var content = UIListContentConfiguration.subtitleCell()
            content.text = model.title
            content.secondaryText = model.date.formatted(date: .abbreviated, time: .omitted)
            cell.contentConfiguration = content
            cell.accessories = [.disclosureIndicator()]
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
        dataSource?.apply(snapshot, animatingDifferences: true)
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
}

// MARK: - Layout

private extension GalleryViewController {
    static func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { sectionIndex, environment in
            let config = UICollectionLayoutListConfiguration(appearance: .plain)
            return NSCollectionLayoutSection.list(using: config, layoutEnvironment: environment)
        }
    }
}
