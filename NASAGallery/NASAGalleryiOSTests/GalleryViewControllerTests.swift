//
//  GalleryViewControllerTests.swift
//  NASAGalleryTests
//
//  Created by Ivo on 16/04/25.
//

import XCTest
import NASAGallery

final class GalleryViewController {
    init(loader: GalleryLoader) {
        
    }
}

final class GalleryViewControllerTests: XCTestCase {

    func test_init_doesNotLoadGallery() {
        let loader = GalleryLoaderSpy()
        _ = GalleryViewController(loader: loader)
        
        XCTAssertEqual(loader.loadCallCount, 0)
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
