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
    private var onViewIsAppearing: ((GalleryViewController) -> Void)?
    
    public convenience init(loader: GalleryLoader) {
        self.init(collectionViewLayout: Self.makeLayout())
        self.loader = loader
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(load), for: .valueChanged)
        self.collectionView.refreshControl = refreshControl
        
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
    
    @objc
    private func load() {
        self.collectionView.refreshControl?.beginRefreshing()

        Task {
            _ = try? await loader?.load()
            self.collectionView.refreshControl?.endRefreshing()
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
