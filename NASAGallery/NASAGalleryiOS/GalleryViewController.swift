//
//  GalleryViewController.swift
//  NASAGalleryiOS
//
//  Created by Ivo on 11/09/25.
//

import Foundation
// FIXME: check what this warning means
import NASAGallery
import UIKit

public final class GalleryViewController: UITableViewController {
    private var loader: GalleryLoader?
    private var onViewIsAppearing: ((GalleryViewController) -> Void)?
    
    public convenience init(loader: GalleryLoader) {
        self.init()
        self.loader = loader
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(load), for: .valueChanged)
        self.refreshControl = refreshControl
        
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
        refreshControl?.beginRefreshing()

        Task {
            _ = try await loader?.load()
            refreshControl?.endRefreshing()
        }
    }
}
