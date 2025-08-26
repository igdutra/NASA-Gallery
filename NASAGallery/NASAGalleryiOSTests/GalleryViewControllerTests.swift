//
//  GalleryViewControllerTests.swift
//  NASAGalleryTests
//
//  Created by Ivo on 16/04/25.
//

import XCTest
import UIKit
import NASAGallery

final class GalleryViewController: UITableViewController {
    private var loader: GalleryLoader?
    
    convenience init(loader: GalleryLoader) {
        self.init()
        self.loader = loader
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .touchUpInside)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        load()
    }
    
    @objc
    func load() {
        Task {
            try await loader?.load()
        }
    }
}

@MainActor
final class GalleryViewControllerTests: XCTestCase {
    func test_init_doesNotLoadGallery() {
        let loader = GalleryLoaderSpy()
        _ = GalleryViewController(loader: loader)
        
        XCTAssertEqual(loader.loadCallCount, 0)
    }
    
    func test_viewDidLoad_loadGallery() async throws {
        // This test verifies that the view controller correctly triggers a gallery load operation
        // when its view is loaded (i.e., `viewDidLoad` is called).
        //
        // We use async/await to precisely await the completion of the loader's `load()` method.
        // This gives us more accurate control over test timing compared to XCTestExpectation,
        // and ensures the assertion is evaluated only after the async loading has finished.
        
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        
        // Wait until the loader's load() method is actually called.
        // This bridges the async Task launched in viewDidLoad and our test's execution flow.
        await loader.awaitUntilCompletion()
        
        XCTAssertEqual(loader.loadCallCount, 1)
    }
    
    func test_pullToRefresh_loadsFeed() async throws {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        
        await loader.awaitUntilCompletion() // Note: Not calling awaitUntilCompletion will cause the test to fail: instances won't be deallocated.
        
        // FIXME: here, watch the simulate pull to refresh fix on iOS 17
        
//        sut.refreshControl?.simulatePullToRefresh()
//        
//        await loader.awaitUntilCompletion()
//
//        XCTAssertEqual(loader.loadCallCount, 2)
    }
}

// MARK: - Helpers

private extension GalleryViewControllerTests {
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: GalleryViewController, loader: GalleryLoaderSpy) {
        let loader = GalleryLoaderSpy()
        let sut = GalleryViewController(loader: loader)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(loader, file: file, line: line)

        return (sut, loader)
    }
}

// MARK: - Spy

final class GalleryLoaderSpy: GalleryLoader {
    private(set) var loadCallCount = 0
    private var continuation: CheckedContinuation<Void, Never>?

    // This method suspends the test execution until `load()` is called,
    // allowing us to synchronize test assertions with async behavior.
    func awaitUntilCompletion() async {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func load() async throws -> [GalleryImage] {
        loadCallCount += 1
        
        // Resume any suspended test waiting for this call.
        continuation?.resume()
        continuation = nil
        
        return []
    }
}

// MARK: - DSLs

private extension UIControl {
    func simulatePullToRefresh() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }
}
