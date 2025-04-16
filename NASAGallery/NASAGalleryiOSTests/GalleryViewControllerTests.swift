//
//  GalleryViewControllerTests.swift
//  NASAGalleryTests
//
//  Created by Ivo on 16/04/25.
//

import XCTest
import UIKit
import NASAGallery

final class GalleryViewController: UIViewController {
    private var loader: GalleryLoader?
    
    convenience init(loader: GalleryLoader) {
        self.init()
        self.loader = loader
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            try await loader?.load()
        }
    }
}

final class GalleryViewControllerTests: XCTestCase {
    func test_init_doesNotLoadGallery() {
        let loader = GalleryLoaderSpy()
        _ = GalleryViewController(loader: loader)
        
        XCTAssertEqual(loader.loadCallCount, 0)
    }
    
    func failingTest_test_viewDidLoad_loadGallery() {
        let loader = GalleryLoaderSpy()
        let sut = GalleryViewController(loader: loader)
        
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(loader.loadCallCount, 1)
    }
}

// MARK: - Spy

final class GalleryLoaderSpy: GalleryLoader {
    var loadCallCount = 0
    
    func load() async throws -> [GalleryImage] {
        loadCallCount += 1
        return []
    }
}
