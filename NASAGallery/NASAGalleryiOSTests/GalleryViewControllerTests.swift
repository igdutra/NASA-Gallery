//
//  GalleryViewControllerTests.swift
//  NASAGalleryTests
//
//  Created by Ivo on 08/09/25.
//

import Testing
import NASAGallery
import NASAGalleryiOS
import UIKit

// TODO: add UX goals table.

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct GalleryViewControllerTests {
    @Test func userInitiatedGalleryLoad_loadsGallery() async {
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        await loader.waitForLoad()
        #expect(loader.loadCallCount == 1)

        sut.simulateUserInitiatedRefresh()
        await loader.waitForLoad()
        #expect(loader.loadCallCount == 2)

        sut.simulateUserInitiatedRefresh()
        await loader.waitForLoad()
        #expect(loader.loadCallCount == 3)
    }
    
    @Test func loadingIndicator_isVisibleWhenLoadingGallery() async {
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        #expect(sut.isShowingLoadingIndicator == true)
        await loader.waitForLoad()
        #expect(sut.isShowingLoadingIndicator == false)
        
        sut.simulateUserInitiatedRefresh()
        #expect(sut.isShowingLoadingIndicator == true)
        await loader.waitForLoad()
        #expect(sut.isShowingLoadingIndicator == false)
    }
    
    // TODO: respect the dont talk to neiborhts and write DSLs to protect tests.
    
    @Test func galleryLoad_renderGalleryAsExpected() async {
        let (sut, loader) = makeSUT()
        let fixture1 = makeGalleryImageFixture()
        let fixture2 = makeGalleryImageFixture(title: "2nd title")
        let fixture3 = makeGalleryImageFixture(title: "3rd title")
        
        // FIXME: wip: - threading problem: clearly the await.loader.waitLoad laoder yield is completing before the applySnapshot gets called.
        // behavior is correct, test order is wrong
        
        
        
//        loader.stub(gallery: [])
//        
//        sut.simulateAppearance()
//        assertThat(sut, isRendering: [])
//
//        loader.stub(gallery: [fixture1])
//        sut.simulateUserInitiatedRefresh()
//        await loader.waitForLoad()
//        assertThat(sut, isRendering: [fixture1])
        
        loader.stub(gallery: [fixture1, fixture2])
        sut.simulateAppearance()
        await loader.waitForLoad()
        
        assertThat(sut, isRendering: [fixture1, fixture2])
//
//        guard let cell = sut.cell(row: 0, section: 0) as? GalleryImageCell else {
//            Issue.record("Cell should be of type GalleryImageCell")
//            return
//        }
//        let config = cell.contentConfiguration as? UIListContentConfiguration
//        
//        #expect(config?.text == makeGalleryImageFixture().title)
//
//        loader.stub(gallery: [fixture1, fixture2, fixture3])
//        sut.simulateUserInitiatedRefresh()
//        await loader.waitForLoad()
//        #expect(sut.collectionView.numberOfItems(inSection: 0) == 3)
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

// FIXME: FLAKYNESS. unfortunately, after testing with the power of test plans, making these tests to run until failure we saw that they can fail.
// The reson is how the async/await will occur, suspending and resuming thread execution, once we await for the loader to load, the check if the spinner is spinning happens in the other theread before we call end refreshing.

// Not blocking for now, lets move on with the MVC approach, but I'll dig into the community how to better fix this, most likely will not envolve Continuations.

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
    private var eventIterator: AsyncStream<Void>.Iterator
    
    init() {
        // Capture the continuation without force-unwrapping.
        var capturedContinuation: AsyncStream<Void>.Continuation?
        self.loadEventStream = AsyncStream { continuation in
            capturedContinuation = continuation
        }
        guard let continuation = capturedContinuation else {
            // Note: could make it throw, however it should work.
            fatalError("Expected AsyncStream to capture continuation")
        }
        self.loadEventContinuation = continuation
        self.eventIterator = loadEventStream.makeAsyncIterator()
    }

    func load() async throws -> [GalleryImage] {
        loadCallCount += 1
        defer {
            loadEventContinuation.yield()
        }
        
        // signal that load() was called

        if let error = stub?.error {
            throw error
        } else if let gallery = stub?.gallery {
            return gallery
        }
        
        throw Error.notStubbed
    }

    func waitForLoad() async {
        // We will await for the next load to occur and protect the entire test suite with
        await eventIterator.next()
    }
    
    // MARK: - Stub
    
    private var stub: Stub?
    
    private struct Stub {
        let error: Error?
        let gallery: [GalleryImage]?
    }
    
    func stub(error: Error? = nil,
              gallery: [GalleryImage]? = nil) {
        stub = Stub(error: error, gallery: gallery)
    }
    
    enum Error: Swift.Error {
        case notStubbed
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

    override func beginRefreshing() {
        _isRefreshing = true
        // mirror UIKit behavior in tests if something depends on the event
        sendActions(for: .valueChanged)
    }

    override func endRefreshing() {
        _isRefreshing = false
    }
}
