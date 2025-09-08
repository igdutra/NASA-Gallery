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
    private var onViewIsAppearing: ((GalleryViewController) -> Void)?
    
    convenience init(loader: GalleryLoader) {
        self.init()
        self.loader = loader
    }

    override func viewDidLoad() {
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
    
    // FIXME: don't initiate refreshControl animation here.
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        
        onViewIsAppearing?(self)
    }
    
    @objc
    func load() {
        refreshControl?.beginRefreshing()

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
        let (sut, loader) = makeSUT()
        let loadExpectation = XCTestExpectation(description: "Wait for load to complete")
        loader.setLoadExpectation(loadExpectation)
        sut.simulateAppearance()
        
        // Wait until the loader's load() method is actually called.
        // This bridges the async Task launched in viewDidLoad and our test's execution flow.
        await fulfillment(of: [loadExpectation], timeout: 0.5)
        
        XCTAssertEqual(loader.loadCallCount, 1)
    }
    
    func test_pullToRefresh_loadsGallery() async throws {
        let (sut, loader) = makeSUT()
        let loadExpectation = XCTestExpectation(description: "Wait for load to complete")
        loader.setLoadExpectation(loadExpectation)
        
        // On Appear
        sut.simulateAppearance()
        XCTAssertEqual(sut.refreshControl?.isRefreshing, true)
        
        // Manually stop and continue
        sut.refreshControl?.endRefreshing()
        XCTAssertEqual(sut.refreshControl?.isRefreshing, false)
        
        // Force with the closure system that loading on ViewIsAppering happens only once
        sut.refreshControl?.simulatePullToRefresh()
        XCTAssertEqual(sut.refreshControl?.isRefreshing, true)

        await fulfillment(of: [loadExpectation], timeout: 0.5)
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
final class GalleryLoaderSpyWithContinuation: GalleryLoader {
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

// MARK: - For Swift Testing referece: use .timeLimit trait + confirmation

//@MainActor
//final class GalleryLoaderSpy: GalleryLoader {
//    var onLoad: (() -> Void)?
//    private(set) var loadCallCount = 0
//
//    func load() async throws -> [GalleryImage] {
//        loadCallCount += 1
//        onLoad?()   // trigger confirmation
//        return []
//    }
//}
//
//@Suite
//struct GalleryViewControllerTests {
//
//    @Test(.timeLimit(.seconds(1))) @MainActor
//    func viewDidLoad_triggersLoaderLoad() async {
//        let loader = GalleryLoaderSpy()
//        let sut = GalleryViewController(loader: loader)
//
//        // confirmation ensures this closure *must* be called during the test.
//        await confirmation("loader.load() was called") { confirm in
//            loader.onLoad = { confirm() }
//            sut.loadViewIfNeeded()
//        }
//
//        #expect(loader.loadCallCount == 1)
//    }
//}
