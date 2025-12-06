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
        
        await withCheckedContinuation { continuation in
            loader.onComplete = {
                continuation.resume()
            }
            
            sut.simulateAppearance()
        }
        
        #expect(loader.loadCallCount == 1)
        loader.onComplete = nil
        
        await withCheckedContinuation { continuation in
            loader.onComplete = {
                continuation.resume()
            }
            
            sut.simulateUserInitiatedRefresh()
        }
        #expect(loader.loadCallCount == 2)
        
        loader.onComplete = nil
        
        await withCheckedContinuation { continuation in
            loader.onComplete = {
                continuation.resume()
            }
            
            sut.simulateUserInitiatedRefresh()
        }
        #expect(loader.loadCallCount == 3)
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

private final class GalleryLoaderSpy: GalleryLoader {
    private(set) var loadCallCount: Int = 0
    var onComplete: (() -> Void)?
    
    func load() async throws -> [GalleryImage] {
        defer { onComplete?() }
        
        loadCallCount += 1
        print(loadCallCount)
        
        print("HEREERERPIEDPAOSUDPASID")
        
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

