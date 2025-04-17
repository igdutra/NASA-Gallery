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
    
    func test_viewDidLoad_loadGallery() {
        let expectation = expectation(description: "Wait for loader.load()")
        let loader = GalleryLoaderSpy(onLoad: { spy in
            expectation.fulfill()
        })

        let sut = GalleryViewController(loader: loader)
        sut.loadViewIfNeeded()
        
        wait(for: [expectation], timeout: 0.5)
        XCTAssertEqual(loader.loadCallCount, 1)
    }
}

// MARK: - Spy

final class GalleryLoaderSpy: GalleryLoader {
    var loadCallCount = 0
    private let onLoad: (GalleryLoaderSpy) -> Void

    init(onLoad: @escaping (GalleryLoaderSpy) -> Void = { _ in }) {
        self.onLoad = onLoad
    }

    func load() async throws -> [GalleryImage] {
        loadCallCount += 1
        onLoad(self)
        return []
    }
}
