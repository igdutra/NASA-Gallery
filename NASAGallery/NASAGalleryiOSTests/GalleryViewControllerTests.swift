//
//  GalleryViewControllerTests.swift
//  NASAGalleryTests
//
//  Created by Ivo on 08/09/25.
//

import Testing
@testable import NASAGallery
import UIKit

// 1- move to production and use ACCESS CONTROL!

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
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        
        onViewIsAppearing?(self)
    }
    
    @objc
    func load() {
        refreshControl?.beginRefreshing()

        Task {
            _ = try await loader?.load()
            refreshControl?.endRefreshing()
        }
    }
}

// MARK: - Swift Testing Suite

@Suite
struct GalleryViewControllerTests {

    // MARK: First test — uses AsyncStream + a global time cap

    /// Verifies the controller triggers exactly one `load()` on first appearance.
    /// We avoid per-assert waits and instead await the next event from the stream.
    @Test(.timeLimit(.minutes(1)))
    @MainActor
    func viewAppearance_triggersSingleLoad() async {
        let (sut, loader) = makeSUT()
        var iterator = loader.loads().makeAsyncIterator()

        #expect(loader.loadCallCount == 0)
        
        sut.simulateAppearance()

        // Wait deterministically for the first load event.
        #expect(await iterator.next() != nil)
        #expect(loader.loadCallCount == 1)
    }

    /// Verifies three sequential loads: on appearance and two manual refreshes.
    /// Uses AsyncStream to await each `load()` deterministically, avoiding temporal coupling.
    @Test(.timeLimit(.minutes(1)))
    @MainActor
    func userInitiatedGalleryLoad_loadsGallery() async {
        let (sut, loader) = makeSUT()
        var calls = loader.loads().makeAsyncIterator()

        sut.simulateAppearance()
        #expect(await calls.next() != nil)
        #expect(loader.loadCallCount == 1)

        sut.simulateUserInitiatedRefresh()
        #expect(await calls.next() != nil)
        #expect(loader.loadCallCount == 2)

        sut.simulateUserInitiatedRefresh()
        #expect(await calls.next() != nil)
        #expect(loader.loadCallCount == 3)
    }
}

// MARK: - Helpers

@MainActor
private extension GalleryViewControllerTests {
    func makeSUT() -> (sut: GalleryViewController, loader: GalleryLoaderSpy) {
        let loader = GalleryLoaderSpy()
        let sut = GalleryViewController(loader: loader)
        return (sut, loader)
    }

}

// MARK: - Spy

/// Spy for `GalleryLoader` that exposes **deterministic** observation of `load()` calls via `AsyncStream`.
///
/// Why AsyncStream?
/// - Each invocation of `load()` yields one event through an internally captured continuation, making call order explicit.
/// - Tests can `await` the next event instead of sleeping/polling, which **removes temporal coupling** and flakiness.
/// - This follows Apple’s async sequence model. See: https://developer.apple.com/documentation/swift/asyncstream/iterator
final class GalleryLoaderSpy: GalleryLoader {
    private(set) var loadCallCount = 0

    private let loadEventStream: AsyncStream<Void>
    private let loadEventContinuation: AsyncStream<Void>.Continuation

    init() {
        // Capture the continuation without force-unwrapping.
        var capturedContinuation: AsyncStream<Void>.Continuation?
        self.loadEventStream = AsyncStream { continuation in
            capturedContinuation = continuation
        }
        guard let continuation = capturedContinuation else {
            fatalError("Expected AsyncStream to capture continuation")
        }
        self.loadEventContinuation = continuation
    }

    func load() async throws -> [GalleryImage] {
        loadCallCount += 1
        loadEventContinuation.yield() // signal that load() was called
        return []
    }

    /// Accessor for the stream of load events, in call order.
    func loads() -> AsyncStream<Void> { loadEventStream }
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

// MARK: - iOS17 Support

private extension GalleryViewController {
    func replaceRefreshControlWithFakeForiOS17Support() {
        guard let real = refreshControl else { return }
        let fake = FakeRefreshControl()

        real.allTargets.forEach { target in
            real.actions(forTarget: target, forControlEvent: .valueChanged)?
                .forEach { action in
                    fake.addTarget(target, action: Selector(action), for: .valueChanged)
                }
        }
        refreshControl = fake
    }
}

private final class FakeRefreshControl: UIRefreshControl {
    private var _isRefreshing = false
    override var isRefreshing: Bool { _isRefreshing }

    override func beginRefreshing() {
        _isRefreshing = true
        // mirror UIKit behavior in tests if something depends on the event
        sendActions(for: .valueChanged)
    }

    override func endRefreshing() {
        _isRefreshing = false
    }
}

