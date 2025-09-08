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


// MARK: - Spy

/// A spy that records calls to `load()` and exposes them
/// as an async sequence of events. Each invocation yields once.
/// This avoids temporal coupling and flaky per-step timeouts.
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

// MARK: - Swift Testing Suite

@Suite
struct GalleryViewControllerTests {

    // Minimal composition root for SUT + Spy
    @MainActor
    private func makeSUT() -> (sut: GalleryViewController, loader: GalleryLoaderSpy) {
        let loader = GalleryLoaderSpy()
        let sut = GalleryViewController(loader: loader)
        return (sut, loader)
    }

    // Trigger the same sequence UIKit would: viewDidLoad → viewIsAppearing
    @MainActor
    private func simulateAppearance(of sut: GalleryViewController) {
        if !sut.isViewLoaded {
            sut.loadViewIfNeeded() // viewDidLoad (sets up refreshControl)
            sut.replaceRefreshControlWithFakeForiOS17Support()
        }
        sut.beginAppearanceTransition(true, animated: false) // will appear
        sut.endAppearanceTransition()                        // is appearing + did appear
    }

    @MainActor
    private func simulateUserInitiatedRefresh(on sut: GalleryViewController) {
        sut.refreshControl?.simulatePullToRefresh()
    }

    // MARK: First test — uses AsyncStream + a global time cap

    /// Verifies the controller triggers exactly one `load()` on first appearance.
    /// We avoid per-assert waits and instead await the next event from the stream.
    @Test(.timeLimit(.minutes(1)))
    @MainActor
    func viewAppearance_triggersSingleLoad() async {
        let (sut, loader) = makeSUT()
        var iterator = loader.loads().makeAsyncIterator()

        #expect(loader.loadCallCount == 0)

        simulateAppearance(of: sut)

        // Wait deterministically for the first load event.
        await #expect(await iterator.next() != nil)
        #expect(loader.loadCallCount == 1)
    }

    /// Verifies three sequential loads: on appearance and two manual refreshes.
    /// Uses AsyncStream to await each `load()` deterministically, avoiding temporal coupling.
    @Test(.timeLimit(.minutes(1)))
    @MainActor
    func load_requestsGallery_threeTimes() async {
        let (sut, loader) = makeSUT()
        var calls = loader.loads().makeAsyncIterator()

        simulateAppearance(of: sut)
        #expect(await calls.next() != nil)
        #expect(loader.loadCallCount == 1)

        simulateUserInitiatedRefresh(on: sut)
        #expect(await calls.next() != nil)
        #expect(loader.loadCallCount == 2)

        simulateUserInitiatedRefresh(on: sut)
        #expect(await calls.next() != nil)
        #expect(loader.loadCallCount == 3)
    }
}

// MARK: - Test DSL / UIControl helpers

private extension UIControl {
    func simulatePullToRefresh() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .valueChanged)?
                .forEach { (target as NSObject).perform(Selector($0)) }
        }
    }
}

// MARK: - iOS17-friendly RefreshControl shim (test-only)

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
