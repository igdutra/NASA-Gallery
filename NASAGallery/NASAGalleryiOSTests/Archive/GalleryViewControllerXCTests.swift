//
//  GalleryViewControllerTests.swift
//  NASAGalleryTests
//
//  Created by Ivo on 16/04/25.
//

import XCTest
import UIKit
import NASAGallery
import NASAGalleryiOS

/*
 
 Author Note: this XCTest was kept as reference but deprecated in favor of its SwiftTesting Version
 
 */
@MainActor
final class GalleryViewControllerXCTests: XCTestCase {
    func test_init_doesNotLoadGallery() {
        let loader = GalleryLoaderSpy()
        _ = GalleryViewController(loader: loader)
        
        XCTAssertEqual(loader.loadCallCount, 0)
    }
    
    func test_viewAppearance_loadGallery() async throws {
        let (sut, loader) = makeSUT()
        let loadExpectation = XCTestExpectation(description: "Wait for load to complete")
        loader.setLoadExpectation(loadExpectation)
        sut.simulateAppearance()
        
        // Wait until the loader's load() method is actually called.
        // This bridges the async Task launched in viewDidLoad and our test's execution flow.
        await fulfillment(of: [loadExpectation], timeout: 0.5)
        
        XCTAssertEqual(loader.loadCallCount, 1)
    }
    
    func test_userInitiatedGalleryLoad_loadsGallery() async throws {
        let (sut, loader) = makeSUT()
        let loadExpectation = XCTestExpectation(description: "Wait for load to complete")
        loader.setLoadExpectation(loadExpectation)
        
        // On Appear
        sut.simulateAppearance()
        XCTAssertEqual(sut.isShowingLoadingIndicator, true)
        
        // Manually stop and continue
        sut.refreshControl?.endRefreshing()
        XCTAssertEqual(sut.isShowingLoadingIndicator, false)
        
        // Force with the closure system that loading on ViewIsAppering happens only once
        sut.simulateUserInitiatedRefresh()
        XCTAssertEqual(sut.isShowingLoadingIndicator, true)

        await fulfillment(of: [loadExpectation], timeout: 0.5)
    }
    
    func test_viewAppearance_hidesLoadingIndicatorOnLoadCompletion() async throws {
        let (sut, loader) = makeSUT()
        let loadExpectation = XCTestExpectation(description: "Wait for load to complete")
        loader.setLoadExpectation(loadExpectation)
        
        // On Appear
        sut.simulateAppearance()
        
        await fulfillment(of: [loadExpectation], timeout: 0.5)
        XCTAssertEqual(sut.isShowingLoadingIndicator, false)
    }
}

// MARK: - Helpers

private extension GalleryViewControllerXCTests {
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: GalleryViewController, loader: GalleryLoaderSpyXCTest) {
        let loader = GalleryLoaderSpyXCTest()
        let sut = GalleryViewController(loader: loader)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(loader, file: file, line: line)

        return (sut, loader)
    }
}

// MARK: - Spy

private final class GalleryLoaderSpyXCTest: GalleryLoader {
    private(set) var loadCallCount = 0
    private var loadExpectation: XCTestExpectation?

    func setLoadExpectation(_ expectation: XCTestExpectation) {
        loadExpectation = expectation
    }

    func load() async throws -> [GalleryImage] {
        loadCallCount += 1
        
        // Resume any suspended test waiting for this call.
        loadExpectation?.fulfill()
        
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

private extension GalleryViewController {
    /// Note: If we simply called sut.viewIsAppearing we would let our view in a weird state.
    /// Thus, we should trigger all he lifeCycle methods, in order, and we can do so by triggering transitions.
    func simulateAppearance() {
        if !isViewLoaded {
            loadViewIfNeeded() // viewDidLoad
            replaceRefreshControlWithFakeForiOS17Support()
        }
        beginAppearanceTransition(true, animated: false) // viewWillAppear
        endAppearanceTransition() // viewIsAppering + viewDidAppear
    }
    
    func simulateUserInitiatedRefresh() {
        refreshControl?.simulatePullToRefresh()
    }

    var isShowingLoadingIndicator: Bool {
        refreshControl?.isRefreshing == true
    }
}

// MARK: - iOS 17 Fake support

/* Author note:
 
 Alternative for this would be to
 let window = UIWindow()
 window.rootViewController = sut
 window.makeKeyAndVisible()
 RunLoop.current.run(until: Date()+1)
 
 not reliable and slow. Also, if running on target with no host application, that won't work.

 */
private extension GalleryViewController {
    func replaceRefreshControlWithFakeForiOS17Support() {
        let fake = FakeRefreshControl()
        
        refreshControl?.allTargets.forEach { target in
            refreshControl?.actions(forTarget: target, forControlEvent: .valueChanged)?.forEach { action in
                fake.addTarget(target, action: Selector(action), for: .valueChanged)
            }
        }
        
        refreshControl = fake
    }
}

private final class FakeRefreshControl: UIRefreshControl {
    private var _isRefreshing: Bool = false
    
    override var isRefreshing: Bool { _isRefreshing }
    
    override func beginRefreshing() {
        _isRefreshing = true
    }
    
    override func endRefreshing() {
        _isRefreshing = false
    }
}

// MARK: - Spy with Continuation - Reference

/// Author Note: Trying some different setups to assert that the loader was called on viewDidLoad
private final class GalleryLoaderSpyWithContinuation: GalleryLoader {
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
