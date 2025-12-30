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

 ✅ Load feed automatically when view is presented

 ✅ Allow customer to manually reload feed (pull to refresh)

 ✅ Show a loading indicator while loading feed

 ✅ Render all loaded feed items (location, image, description)

 >>  Image loading experience
    ✅ Load when image view is visible (on screen)
    ✅ Cancel when image view is out of screen
    ✅ Show a loading indicator while loading image (shimmer)
    ✅ Option to retry on image download error
    ✅ Preload when image view is near visible

 */

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct GalleryViewControllerTests {
    @Test func userInitiatedGalleryLoad_loadsGallery() async {
        let (sut, loader, _) = makeSUT()

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
        let (sut, _, _) = makeSUT()

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

    @Test func galleryLoad_renderGalleryAsExpected() async {
        let (sut, loader, _) = makeSUT()
        let fixture1 = makeGalleryImageFixture()
        let fixture2 = makeGalleryImageFixture(title: "2nd title")
        let fixture3 = makeGalleryImageFixture(title: "3rd title")

        loader.stub(gallery: [])
        sut.simulateAppearance()
        await sut.waitForRefreshToEnd()

        loader.stub(gallery: [fixture1])
        sut.simulateUserInitiatedRefresh()
        await sut.waitForRefreshToEnd()

        assertThat(sut, isRendering: [fixture1])

        loader.stub(gallery: [fixture1, fixture2, fixture3])
        sut.simulateUserInitiatedRefresh()
        await sut.waitForRefreshToEnd()

        assertThat(sut, isRendering: [fixture1, fixture2, fixture3])
    }

    @Test func galleryLoad_onError_doesNotAlterCurrentlyRenderedGallery() async {
        let (sut, loader, _) = makeSUT()
        let fixture1 = makeGalleryImageFixture()
        let fixture2 = makeGalleryImageFixture(title: "2nd title")

        // Load initial gallery successfully
        loader.stub(gallery: [fixture1, fixture2])
        sut.simulateAppearance()
        await sut.waitForRefreshToEnd()

        assertThat(sut, isRendering: [fixture1, fixture2])

        // Trigger refresh that fails with error
        loader.stub(error: anyNSError())
        sut.simulateUserInitiatedRefresh()
        await sut.waitForRefreshToEnd()

        // Should still render the previously loaded gallery
        assertThat(sut, isRendering: [fixture1, fixture2])
    }

    // MARK: - Image Loading Experience

    @Test func galleryImageView_loadsImageURLWhenVisible() async {
        let fixture0 = makeGalleryImageFixture(urlString: "https://url-0.com")
        let fixture1 = makeGalleryImageFixture(urlString: "https://url-1.com")
        let (sut, loader, imageLoader) = makeSUT()
        loader.stub(gallery: [fixture0, fixture1])

        sut.simulateAppearance()
        await sut.waitForRefreshToEnd()
        #expect(imageLoader.loadedImageURLs.isEmpty)

        // No await needed: loadImageData(from:) is SYNCHRONOUS and tracks the URL immediately
        // This tests that loading STARTS when cell becomes visible
        // The actual async work (task.value) is tested in loading indicator tests
        sut.simulateGalleryImageViewVisible(at: 0)
        #expect(imageLoader.loadedImageURLs == [fixture0.url])

        sut.simulateGalleryImageViewVisible(at: 1)
        #expect(imageLoader.loadedImageURLs == [fixture0.url, fixture1.url])
    }

    @Test func galleryImageView_cancelsImageLoadWhenNotVisibleAnymore() async {
        let fixture0 = makeGalleryImageFixture(urlString: "https://url-0.com")
        let fixture1 = makeGalleryImageFixture(urlString: "https://url-1.com")
        let (sut, loader, imageLoader) = makeSUT()
        loader.stub(gallery: [fixture0, fixture1])

        sut.simulateAppearance()
        await sut.waitForRefreshToEnd()

        sut.simulateGalleryImageViewVisible(at: 0)
        #expect(imageLoader.cancelledImageURLs.isEmpty)

        sut.simulateGalleryImageViewNotVisible(at: 0)
        #expect(imageLoader.cancelledImageURLs == [fixture0.url])

        sut.simulateGalleryImageViewVisible(at: 1)
        #expect(imageLoader.cancelledImageURLs == [fixture0.url])

        sut.simulateGalleryImageViewNotVisible(at: 1)
        #expect(imageLoader.cancelledImageURLs == [fixture0.url, fixture1.url])
    }

    // Note how for this test, as we first complete THEN stop the loading as last, we need to inject a closure in production code..
    @Test func galleryImageView_showsLoadingIndicatorWhileLoadingImage() async {
        let fixture0 = makeGalleryImageFixture(urlString: "https://url-0.com")
        let (sut, loader, imageLoader) = makeSUT()
        loader.stub(gallery: [fixture0])

        sut.simulateAppearance()
        await sut.waitForRefreshToEnd()

        let cell0 = sut.simulateGalleryImageViewVisible(at: 0)

        // DURING loading - indicator should be animating
        #expect(cell0?.isLoading == true)

        // Wait for stopLoading() to be called after the ViewController's Task completes
        // This ensures we don't assert before the async UI update finishes
        await withCheckedContinuation { continuation in
            cell0?.onStopLoading = { continuation.resume() }
            imageLoader.completeImageLoading(with: Data(), at: 0)
        }

        // AFTER loading - indicator should stop animating
        #expect(cell0?.isLoading == false)
    }

    @Test func galleryImageView_displaysRetryOnImageLoadError() async {
        let fixture0 = makeGalleryImageFixture(urlString: "https://url-0.com")
        let (sut, loader, imageLoader) = makeSUT()
        loader.stub(gallery: [fixture0])

        sut.simulateAppearance()
        await sut.waitForRefreshToEnd()

        let cell0 = sut.simulateGalleryImageViewVisible(at: 0)

        // BEFORE error - no retry button
        #expect(cell0?.isShowingRetry == false)

        // Wait for error handling to complete and retry button to be shown
        await withCheckedContinuation { continuation in
            cell0?.onShowRetry = { continuation.resume() }
            imageLoader.completeImageLoadingWithError(anyNSError(), at: 0)
        }

        // AFTER error - retry button appears
        #expect(cell0?.isShowingRetry == true)
    }

//    @Test func galleryImageView_retriesImageLoadOnRetryButtonTap() async {
//        let fixture0 = makeGalleryImageFixture(urlString: "https://url-0.com")
//        let (sut, loader, imageLoader) = makeSUT()
//        loader.stub(gallery: [fixture0])
//
//        sut.simulateAppearance()
//        await sut.waitForRefreshToEnd()
//
//        let cell0 = sut.simulateGalleryImageViewVisible(at: 0)
//
//        // Trigger first load failure
//        await withCheckedContinuation { continuation in
//            cell0?.onShowRetry = { continuation.resume() }
//            imageLoader.completeImageLoadingWithError(anyNSError(), at: 0)
//        }
//
//        #expect(cell0?.isShowingRetry == true)
//        #expect(imageLoader.loadedImageURLs == [fixture0.url])
//
//        // User taps retry button
//        cell0?.simulateRetryAction()
//
//        // Should trigger NEW image load attempt
//        #expect(imageLoader.loadedImageURLs == [fixture0.url, fixture0.url])
//
//        // Complete successfully this time
//        let imageData = UIImage(data: UIImage.make(withColor: .red).pngData()!)?.pngData()
//        await withCheckedContinuation { continuation in
//            cell0?.onDisplayImage = { continuation.resume() }
//            imageLoader.completeImageLoading(with: imageData!, at: 1)  // Index 1 for second load
//        }
//
//        #expect(cell0?.renderedImage == imageData)
//        #expect(cell0?.isShowingRetry == false)
//    }

    @Test func galleryImageView_displaysRetryOnInvalidImageData() async {
        let fixture0 = makeGalleryImageFixture(urlString: "https://url-0.com")
        let (sut, loader, imageLoader) = makeSUT()
        loader.stub(gallery: [fixture0])

        sut.simulateAppearance()
        await sut.waitForRefreshToEnd()

        let cell0 = sut.simulateGalleryImageViewVisible(at: 0)

        // BEFORE invalid data - no retry button
        #expect(cell0?.isShowingRetry == false)

        // Complete with invalid image data (not a valid image format)
        let invalidImageData = Data("invalid image data".utf8)

        await withCheckedContinuation { continuation in
            cell0?.onShowRetry = { continuation.resume() }
            imageLoader.completeImageLoading(with: invalidImageData, at: 0)
        }

        // AFTER invalid data - retry button appears and loading stops
        #expect(cell0?.isShowingRetry == true)
        #expect(cell0?.isLoading == false)
        #expect(cell0?.renderedImage == nil)
    }

    @Test func galleryImageView_preloadsImageWhenCellIsNearVisible() async {
        let fixture0 = makeGalleryImageFixture(urlString: "https://url-0.com")
        let fixture1 = makeGalleryImageFixture(urlString: "https://url-1.com")
        let fixture2 = makeGalleryImageFixture(urlString: "https://url-2.com")
        let (sut, loader, imageLoader) = makeSUT()
        loader.stub(gallery: [fixture0, fixture1, fixture2])

        sut.simulateAppearance()
        await sut.waitForRefreshToEnd()

        // No images loaded yet
        #expect(imageLoader.loadedImageURLs.isEmpty)

        // Simulate UICollectionView telling us index 1 and 2 are about to become visible
        sut.simulatePrefetchImages(at: [1, 2])

        // Should start loading images for those indices
        #expect(imageLoader.loadedImageURLs == [fixture1.url, fixture2.url])
    }

    @Test func galleryImageView_cancelsPrefetchWhenCellMovesAway() async {
        let fixture0 = makeGalleryImageFixture(urlString: "https://url-0.com")
        let fixture1 = makeGalleryImageFixture(urlString: "https://url-1.com")
        let (sut, loader, imageLoader) = makeSUT()
        loader.stub(gallery: [fixture0, fixture1])

        sut.simulateAppearance()
        await sut.waitForRefreshToEnd()

        // Start prefetching for indices 0 and 1
        sut.simulatePrefetchImages(at: [0, 1])
        #expect(imageLoader.loadedImageURLs == [fixture0.url, fixture1.url])
        #expect(imageLoader.cancelledImageURLs.isEmpty)

        // User scrolls quickly - cells 0 and 1 move away before becoming visible
        sut.simulateCancelPrefetchImages(at: [0])
        #expect(imageLoader.cancelledImageURLs == [fixture0.url])

        sut.simulateCancelPrefetchImages(at: [1])
        #expect(imageLoader.cancelledImageURLs == [fixture0.url, fixture1.url])
    }

    @Test func galleryImageView_rendersImageLoadedFromURL() async {
        let fixture0 = makeGalleryImageFixture(urlString: "https://url-0.com")
        let fixture1 = makeGalleryImageFixture(urlString: "https://url-1.com")
        let (sut, loader, imageLoader) = makeSUT()
        loader.stub(gallery: [fixture0, fixture1])

        sut.simulateAppearance()
        await sut.waitForRefreshToEnd()

        let cell0 = sut.simulateGalleryImageViewVisible(at: 0)
        let cell1 = sut.simulateGalleryImageViewVisible(at: 1)
        #expect(cell0?.renderedImage == nil, "Expected no image for first view while loading first image")
        #expect(cell1?.renderedImage == nil, "Expected no image for second view while loading second image")

        // Create image data and normalize through the same pipeline as production code
        // This ensures PNG encoding is identical (UIImage(data:) -> pngData() round-trip)
        let imageData0 = UIImage(data: UIImage.make(withColor: .red).pngData()!)?.pngData()
        await withCheckedContinuation { continuation in
            cell0?.onDisplayImage = { continuation.resume() }
            imageLoader.completeImageLoading(with: imageData0!, at: 0)
        }
        #expect(cell0?.renderedImage == imageData0, "Expected image for first view once first image loading completes successfully")
        #expect(cell1?.renderedImage == nil, "Expected no image state change for second view once first image loading completes successfully")

        let imageData1 = UIImage(data: UIImage.make(withColor: .blue).pngData()!)?.pngData()
        await withCheckedContinuation { continuation in
            cell1?.onDisplayImage = { continuation.resume() }
            imageLoader.completeImageLoading(with: imageData1!, at: 1)
        }
        #expect(cell0?.renderedImage == imageData0, "Expected no image state change for first view once second image loading completes successfully")
        #expect(cell1?.renderedImage == imageData1, "Expected image for second view once second image loading completes successfully")
    }
}

// MARK: - Helpers

@MainActor
private extension GalleryViewControllerTests {
    // TODO: add memory leak tracking
    func makeSUT() -> (sut: GalleryViewController, loader: GalleryLoaderSpy, imageLoader: GalleryImageDataLoaderSpy) {
        let loader = GalleryLoaderSpy()
        let imageLoader = GalleryImageDataLoaderSpy()
        let sut = GalleryViewController(loader: loader, imageLoader: imageLoader)
        return (sut, loader, imageLoader)
    }

    func anyNSError() -> NSError {
        NSError(domain: "any error", code: 0)
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

            #expect(cell.titleText == image.title, sourceLocation: sourceLocation)
        }
    }
}

// MARK: - Spies

private final class GalleryImageDataLoaderSpy: GalleryImageDataLoader {
    private(set) var loadedImageURLs: [URL] = []
    private(set) var cancelledImageURLs: [URL] = []
    private var spyTasks: [SpyTask] = []
    
    /// Completion handler called when any image task completes. Used with withCheckedContinuation for async waiting.
    var onComplete: (() -> Void)?

    /// Synchronously creates and tracks an image loading task.
    /// The URL is recorded immediately in loadedImageURLs.
    /// The async completion (task.value) waits until completeImageLoading() is called from tests.
    func loadImageData(from url: URL) -> GalleryImageDataLoaderTask {
        loadedImageURLs.append(url)  // SYNCHRONOUS tracking

        let spyTask = SpyTask(
            onCancel: { [weak self] in
                self?.cancelledImageURLs.append(url)
            },
            onComplete: { [weak self] in
                self?.onComplete?()
            }
        )
        spyTasks.append(spyTask)

        return spyTask
    }

    // MARK: - Test Helpers

    func completeImageLoading(with data: Data = Data(), at index: Int = 0) {
        guard index < spyTasks.count else { return }
        spyTasks[index].complete(with: data)
    }

    func completeImageLoadingWithError(_ error: Error, at index: Int = 0) {
        guard index < spyTasks.count else { return }
        spyTasks[index].complete(with: error)
    }

    // MARK: - SpyTask

    /// A test double for GalleryImageDataLoaderTask that implements a promise pattern.
    ///
    /// Key behaviors:
    /// 1. If `value` is awaited BEFORE complete() is called → suspends until complete()
    /// 2. If complete() is called BEFORE `value` is awaited → stores result for immediate return
    /// 3. This allows tests to control WHEN async work completes for testing intermediate states
    private final class SpyTask: GalleryImageDataLoaderTask {
        private var result: Result<Data, Error>?
        private var continuation: CheckedContinuation<Data, Error>?
        private let onCancel: () -> Void
        private let onComplete: () -> Void
        private var isCancelled = false

        init(onCancel: @escaping () -> Void, onComplete: @escaping () -> Void) {
            self.onCancel = onCancel
            self.onComplete = onComplete
        }

        var value: Data {
            get async throws {
                // If already completed, return immediately
                if let result {
                    return try result.get()
                }

                // Wait for complete() to be called from test
                return try await withCheckedThrowingContinuation { continuation in
                    self.continuation = continuation
                }
            }
        }

        func complete(with data: Data) {
            if let continuation {
                continuation.resume(returning: data)
            } else {
                result = .success(data)
            }
            onComplete()
        }

        func complete(with error: Error) {
            if let continuation {
                continuation.resume(throwing: error)
            } else {
                result = .failure(error)
            }
            onComplete()
        }

        func cancel() {
            isCancelled = true
            onCancel()
        }
    }
}

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
    private var stubbedResult: Result<[GalleryImage], Error> = .success([])

    /// Completion handler called when load() finishes. Used with withCheckedContinuation for async waiting.
    var onComplete: (() -> Void)?

    /// Stubs the gallery items that will be returned by load()
    func stub(gallery: [GalleryImage]) {
        stubbedResult = .success(gallery)
    }

    /// Stubs an error that will be thrown by load()
    func stub(error: Error) {
        stubbedResult = .failure(error)
    }

    func load() async throws -> [GalleryImage] {
        defer { onComplete?() }

        loadCallCount += 1

        return try stubbedResult.get()
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

private extension GalleryImageCell {
    var isLoading: Bool {
        activityIndicator.isAnimating
    }

    var isShowingRetry: Bool {
        !retryButton.isHidden
    }

    var titleText: String? {
        titleLabel.text
    }

    var renderedImage: Data? {
        imageView.image?.pngData()
    }
}

private extension UIImage {
    static func make(withColor color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(color.cgColor)
        context.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
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

    @discardableResult
    func simulateGalleryImageViewVisible(at index: Int, section: Int = 0) -> GalleryImageCell? {
        let indexPath = IndexPath(row: index, section: section)
        guard let cell = cell(row: index, section: section) as? GalleryImageCell else { return nil }

        // Simulate UIKit calling willDisplay delegate method
        let delegate = collectionView.delegate
        delegate?.collectionView?(collectionView, willDisplay: cell, forItemAt: indexPath)

        return cell
    }

    func simulateGalleryImageViewNotVisible(at index: Int, section: Int = 0) {
        let indexPath = IndexPath(row: index, section: section)
        guard let cell = cell(row: index, section: section) as? GalleryImageCell else { return }

        // Simulate UIKit calling didEndDisplaying delegate method
        let delegate = collectionView.delegate
        delegate?.collectionView?(collectionView, didEndDisplaying: cell, forItemAt: indexPath)
    }

    func simulatePrefetchImages(at indices: [Int], section: Int = 0) {
        let indexPaths = indices.map { IndexPath(row: $0, section: section) }
        let prefetchDataSource = collectionView.prefetchDataSource
        prefetchDataSource?.collectionView(collectionView, prefetchItemsAt: indexPaths)
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

