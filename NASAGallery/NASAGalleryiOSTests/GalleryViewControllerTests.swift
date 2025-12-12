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

private final class GalleryLoaderSpy: GalleryLoader {
    private(set) var loadCallCount: Int = 0
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
