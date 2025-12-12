//
//  GalleryViewControllerTests.swift
//  NASAGalleryiOSTests
//
//  Created by Ivo on 06/12/25.
//

import Testing
import NASAGallery
import NASAGalleryiOS
import UIKit


/*
 // possibly read https://www.donnywals.com/using-swifts-async-await-to-build-an-image-loader/
 
 > Load feed automatically when view is presented

 > Allow customer to manually reload feed (pull to refresh)

 > Show a loading indicator while loading feed

 > Render all loaded feed items (location, image, description)

 >>  Image loading experience
    - Load when image view is visible (on screen)
    - Cancel when image view is out of screen
    - Show a loading indicator while loading image (shimmer)
    - Option to retry on image download error
    - Preload when image view is near visibleU
 
 */

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct GalleryViewControllerTests {
    @Test func userInitiatedGalleryLoad_loadsGallery() async {
        let (sut, loader) = makeSUT()

        await performAndWaitForLoad(loader) {
            sut.simulateAppearance()
        }
        #expect(loader.loadCallCount == 1)

        await performAndWaitForLoad(loader) {
            sut.simulateUserInitiatedRefresh()
        }
        #expect(loader.loadCallCount == 2)

        await performAndWaitForLoad(loader) {
            sut.simulateUserInitiatedRefresh()
        }
        #expect(loader.loadCallCount == 3)
    }
    
    @Test func loadingIndicator_isVisibleWhenLoadingGallery() async {
        let (sut, _) = makeSUT()

        sut.simulateAppearance()
        await sut.waitForBeginRefreshing()
        #expect(sut.isShowingLoadingIndicator == true)
        await sut.waitForRefreshToEnd()
        #expect(sut.isShowingLoadingIndicator == false)

        sut.simulateUserInitiatedRefresh()
        await sut.waitForBeginRefreshing()
        #expect(sut.isShowingLoadingIndicator == true)
        await sut.waitForRefreshToEnd()
        #expect(sut.isShowingLoadingIndicator == false)
    }
}

// MARK: - Helpers

@MainActor
private extension GalleryViewControllerTests {
    // TODO: add memory leak tracking
    func makeSUT() -> (sut: GalleryViewController, loader: GalleryLoaderSpy) {
        let loader = GalleryLoaderSpy()
        let sut = GalleryViewController(loader: loader)
        return (sut, loader)
    }

    /// Performs an action and suspends until the loader completes.
    ///
    /// Uses `withCheckedContinuation` (NOT `confirmation`) to properly suspend and wait
    /// for the loader's async work to finish. The continuation resumes when loader.onComplete is called.
    ///
    /// - Parameters:
    ///   - loader: The spy that will call onComplete when load() finishes
    ///   - action: The action that triggers the load (e.g., simulateAppearance())
    func performAndWaitForLoad(
        _ loader: GalleryLoaderSpy,
        action: () -> Void
    ) async {
        await withCheckedContinuation { continuation in
            loader.onComplete = { continuation.resume() }
            action()
        }
        loader.onComplete = nil
    }

    func assertThat(_ sut: GalleryViewController, isRendering gallery: [GalleryImage], inSection section: Int = 0, sourceLocation: SourceLocation = #_sourceLocation) {
        #expect(sut.numberOfGalleryImages() == gallery.count, sourceLocation: sourceLocation)
        
        for (index, image) in gallery.enumerated() {
            guard let cell = sut.cell(row: index, section: section) as? GalleryImageCell else {
                Issue.record("Cell should be of type GalleryImageCell", sourceLocation: sourceLocation)
                return
            }
            let config = cell.contentConfiguration as? UIListContentConfiguration
            
            #expect(config?.text == image.title, sourceLocation: sourceLocation)
        }
    }
}

// MARK: - Spy

/*
 IMPORTANT: Continuation vs Confirmation

 This spy uses a completion handler pattern (onComplete) to signal when async work finishes.
 When testing async code, we need to wait for this completion before making assertions.

 ✅ CORRECT: Use withCheckedContinuation (Swift Concurrency)
    - Suspends execution and waits for continuation.resume() to be called
    - Works with unstructured Tasks that complete "later"
    - See performAndWaitForLoad() helper below

 ❌ WRONG: Use confirmation (Swift Testing)
    - Does NOT suspend - expects confirmation BEFORE the confirmation() block returns
    - Fails when used with unstructured Tasks (like our GalleryViewController.load())
    - The test exits before the async work completes → flaky tests

 From Apple's Migration Guide:
 "For a function that takes a completion handler but which doesn't use await,
  a Swift continuation can be used to convert the call into an async-compatible one."

 Reference: https://developer.apple.com/documentation/testing/migratingfromxctest

 Note: Easy to confuse "continuation" and "confirmation" - they're very close in name but fundamentally different!
 */
private final class GalleryLoaderSpy: GalleryLoader {
    private(set) var loadCallCount: Int = 0

    /// Completion handler called when load() finishes. Used with withCheckedContinuation for async waiting.
    var onComplete: (() -> Void)?

    func load() async throws -> [GalleryImage] {
        defer { onComplete?() }

        loadCallCount += 1

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
        collectionView.refreshControl?.simulatePullToRefresh()
    }

    var isShowingLoadingIndicator: Bool {
        collectionView.refreshControl?.isRefreshing == true
    }
    
    func waitForBeginRefreshing() async {
        guard let fake = collectionView.refreshControl as? FakeRefreshControl else { return }
        await fake.waitForBeginRefreshing()
    }

    func waitForRefreshToEnd() async {
        guard let fake = collectionView.refreshControl as? FakeRefreshControl else { return }
        await fake.waitForEndRefreshing()
    }
    
    func cell(row: Int, section: Int) -> UICollectionViewCell? {
        guard numberOfRows(in: section) > row else { return nil }
        let ds = collectionView.dataSource
        let index = IndexPath(row: row, section: section)
        return ds?.collectionView(collectionView, cellForItemAt: index)
    }
    
    func numberOfRows(in section: Int) -> Int {
        collectionView.numberOfSections > section ? collectionView.numberOfItems(inSection: section) : 0
    }
    
    func numberOfGalleryImages(in section: Int = 0) -> Int {
        collectionView.numberOfItems(inSection: section)
    }
}

// MARK: - iOS17 Support

private extension GalleryViewController {
    func replaceRefreshControlWithFakeForiOS17Support() {
        guard let real = collectionView.refreshControl else { return }
        let fake = FakeRefreshControl()

        real.allTargets.forEach { target in
            real.actions(forTarget: target, forControlEvent: .valueChanged)?
                .forEach { action in
                    fake.addTarget(target, action: Selector(action), for: .valueChanged)
                }
        }
        collectionView.refreshControl = fake
    }
}

private final class FakeRefreshControl: UIRefreshControl {
    private var _isRefreshing = false
    override var isRefreshing: Bool { _isRefreshing }

    private var beginContinuations: [CheckedContinuation<Void, Never>] = []
    private var endContinuations: [CheckedContinuation<Void, Never>] = []

    override func beginRefreshing() {
        _isRefreshing = true
        // Resume any waiters for begin
        let continuations = beginContinuations
        beginContinuations.removeAll()
        continuations.forEach { $0.resume() }
        // mirror UIKit behavior in tests if something depends on the event
        sendActions(for: .valueChanged)
    }

    override func endRefreshing() {
        _isRefreshing = false
        // Resume any waiters for end
        let continuations = endContinuations
        endContinuations.removeAll()
        continuations.forEach { $0.resume() }
    }

    func waitForBeginRefreshing() async {
        if _isRefreshing { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            beginContinuations.append(continuation)
        }
    }

    func waitForEndRefreshing() async {
        if !_isRefreshing { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            endContinuations.append(continuation)
        }
    }
}
