# Essential Feed PR Analysis: Multi MVC Refactoring

**PR URL:** https://github.com/essentialdevelopercom/essential-feed-case-study/pull/21

## Executive Summary

This PR refactors the feed UI layer by separating concerns across multiple controllers and introducing a composer pattern for dependency management. The key architectural change is moving from a monolithic `FeedViewController` to a clearer separation of responsibilities:

- **FeedRefreshViewController** - Manages refresh control and feed loading
- **FeedImageCellController** - Manages individual cell configuration and image loading
- **FeedUIComposer** - Composes dependencies and wires up controllers

### Statistics
- **Total new concepts in PR:** 3 (FeedRefreshViewController, FeedImageCellController, FeedUIComposer)
- **Already implemented in NASA Gallery:** ❌ None (monolithic architecture currently)
- **New implementations needed:** ✅ 3 components to refactor

### Current NASA Gallery Architecture

NASA Gallery currently uses a **monolithic architecture**:
- `GalleryViewController` handles ALL responsibilities:
  - Gallery loading (via loader injection)
  - Refresh control management
  - Image loading and cancellation
  - Cell configuration
  - Prefetching logic

This works, but violates Single Responsibility Principle and makes testing more coupled.

---

## Test Extraction

### Architectural Components (Not Individual Tests)

This PR focuses on **refactoring production code** to improve architecture. The tests themselves **don't change** - they still validate the same behaviors. What changes is HOW the implementation achieves those behaviors.

#### Essential Feed Components Created:

1. **FeedRefreshViewController** - Separate controller for refresh logic
   - Purpose: Manages UIRefreshControl and triggers feed loading
   - Pattern: Delegate pattern via closure (`onRefresh`)
   - Status: ❌ NEW (need to extract from GalleryViewController)

2. **FeedImageCellController** - Separate controller per cell
   - Purpose: Manages image loading, retry logic, and cell configuration for ONE feed item
   - Pattern: Cell controller pattern (controller-per-cell)
   - Status: ❌ NEW (need to extract from GalleryViewController)

3. **FeedUIComposer** - Dependency composition
   - Purpose: Factory that creates and wires up all controllers
   - Pattern: Composer/Factory pattern
   - Status: ❌ NEW (need to create)

4. **Test Helper Extraction** - Organized test utilities
   - Purpose: Separate test helpers into focused extension files
   - Pattern: Test DSL organization
   - Status: ⚠️ PARTIAL (NASA Gallery has helpers, but not as organized)

---

## Implementation Plan

### **IMPORTANT: This is a REFACTORING, not new features**

All the tests in `GalleryViewControllerTests.swift` **already pass**. This refactoring will:
1. Keep ALL existing tests unchanged
2. Refactor production code to use multiple controllers
3. Tests should still pass after refactoring
4. Improve architecture without changing behavior

---

## Component #1: FeedRefreshViewController

### Purpose
Extract refresh control management into a dedicated controller that handles:
- Creating and managing UIRefreshControl
- Triggering feed loading
- Delegating loaded feed back to owner via closure

### Original Essential Feed Code

```swift
final class FeedRefreshViewController: NSObject {
	private(set) lazy var view: UIRefreshControl = {
		let view = UIRefreshControl()
		view.addTarget(self, action: #selector(refresh), for: .valueChanged)
		return view
	}()

	private let feedLoader: FeedLoader

	init(feedLoader: FeedLoader) {
		self.feedLoader = feedLoader
	}

	var onRefresh: (([FeedImage]) -> Void)?

	@objc func refresh() {
		view.beginRefreshing()
		feedLoader.load { [weak self] result in
			if let feed = try? result.get() {
				self?.onRefresh?(feed)
			}
			self?.view.endRefreshing()
		}
	}
}
```

### NASA Gallery Adaptation (Async/Await)

```swift
final class GalleryRefreshViewController: NSObject {
    private(set) lazy var view: UIRefreshControl = {
        let view = UIRefreshControl()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }()

    private let galleryLoader: GalleryLoader

    init(galleryLoader: GalleryLoader) {
        self.galleryLoader = galleryLoader
    }

    var onRefresh: (([GalleryImage]) -> Void)?

    @objc func refresh() {
        view.beginRefreshing()

        Task { @MainActor in
            defer { view.endRefreshing() }

            do {
                let gallery = try await galleryLoader.load()
                onRefresh?(gallery)
            } catch {
                // Silently ignore errors - keep current gallery displayed
            }
        }
    }
}
```

### Key Differences from Essential Feed

1. **Async/await instead of completion handlers**
   - Essential Feed: `feedLoader.load { completion }` (callback)
   - NASA Gallery: `try await galleryLoader.load()` (async)

2. **Task management**
   - Essential Feed: No explicit task management (synchronous flow)
   - NASA Gallery: Wrap in `Task { @MainActor }` for async work

3. **Error handling**
   - Essential Feed: `if let feed = try? result.get()` (ignore errors silently)
   - NASA Gallery: `do/catch` with silent error handling (same behavior)

4. **Defer pattern**
   - Both use defer, but NASA Gallery's is simpler (no weak self needed in defer)

---

## Component #2: FeedImageCellController

### Purpose
Extract image loading and cell configuration into a dedicated controller that handles ONE cell's entire lifecycle:
- Cell creation and configuration
- Image loading on visibility
- Image cancellation on scroll away
- Retry on error
- Prefetching

### Original Essential Feed Code

```swift
final class FeedImageCellController {
	private var task: FeedImageDataLoaderTask?
	private let model: FeedImage
	private let imageLoader: FeedImageDataLoader

	init(model: FeedImage, imageLoader: FeedImageDataLoader) {
		self.model = model
		self.imageLoader = imageLoader
	}

	func view() -> UITableViewCell {
		let cell = FeedImageCell()
		cell.locationContainer.isHidden = (model.location == nil)
		cell.locationLabel.text = model.location
		cell.descriptionLabel.text = model.description
		cell.feedImageView.image = nil
		cell.feedImageRetryButton.isHidden = true
		cell.feedImageContainer.startShimmering()

		let loadImage = { [weak self, weak cell] in
			guard let self = self else { return }

			self.task = self.imageLoader.loadImageData(from: self.model.url) { [weak cell] result in
				let data = try? result.get()
				let image = data.map(UIImage.init) ?? nil
				cell?.feedImageView.image = image
				cell?.feedImageRetryButton.isHidden = (image != nil)
				cell?.feedImageContainer.stopShimmering()
			}
		}

		cell.onRetry = loadImage
		loadImage()

		return cell
	}

	func preload() {
		task = imageLoader.loadImageData(from: model.url) { _ in }
	}

	func cancelLoad() {
		task?.cancel()
	}
}
```

### NASA Gallery Adaptation (Async/Await)

```swift
final class GalleryImageCellController {
    private var task: GalleryImageDataLoaderTask?
    private let model: GalleryImage
    private let imageLoader: GalleryImageDataLoader

    init(model: GalleryImage, imageLoader: GalleryImageDataLoader) {
        self.model = model
        self.imageLoader = imageLoader
    }

    func view(in collectionView: UICollectionView, at indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: GalleryImageCell.reuseIdentifier,
            for: indexPath
        ) as! GalleryImageCell

        cell.titleLabel.text = model.title
        cell.imageView.image = nil
        cell.hideRetry()
        cell.startLoading()

        let loadImage = { [weak self, weak cell] in
            guard let self = self else { return }

            // Create task only if not already created (reuse prefetch task if available)
            if self.task == nil {
                self.task = self.imageLoader.loadImageData(from: self.model.url)
            }

            guard let task = self.task else { return }

            Task { @MainActor in
                do {
                    let data = try await task.value
                    guard let image = UIImage(data: data) else {
                        // Invalid image data - show retry
                        cell?.stopLoading()
                        cell?.showRetry()
                        return
                    }
                    cell?.display(image)
                    cell?.stopLoading()
                } catch {
                    cell?.stopLoading()
                    cell?.showRetry()
                }
            }
        }

        cell.onRetry = loadImage
        loadImage()

        return cell
    }

    func preload() {
        guard task == nil else { return }
        task = imageLoader.loadImageData(from: model.url)

        // Start background loading
        Task {
            do {
                _ = try await task?.value
            } catch {
                // Silently ignore prefetch errors
            }
        }
    }

    func cancelLoad() {
        task?.cancel()
        task = nil
    }
}
```

### Key Differences from Essential Feed

1. **UICollectionView vs UITableView**
   - Essential Feed: Creates cell directly `FeedImageCell()`
   - NASA Gallery: Dequeues from collection view with identifier

2. **Cell registration**
   - Essential Feed: Manual cell creation
   - NASA Gallery: Cell reuse identifier pattern (need to add static property)

3. **Async/await pattern**
   - Essential Feed: Completion handler `loadImageData(completion:)`
   - NASA Gallery: `try await task.value` pattern

4. **Task reuse logic**
   - Essential Feed: Always creates new task in `view()`
   - NASA Gallery: Reuses prefetched task if available (`if task == nil`)

5. **Model properties**
   - Essential Feed: `location`, `description` (optional strings)
   - NASA Gallery: `title` (simpler model)

---

## Component #3: FeedUIComposer

### Purpose
Factory pattern to compose and wire up all dependencies. This is the ONLY public API - all controllers become internal implementation details.

### Original Essential Feed Code

```swift
public final class FeedUIComposer {
	private init() {}

	public static func feedComposedWith(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) -> FeedViewController {
		let refreshController = FeedRefreshViewController(feedLoader: feedLoader)
		let feedController = FeedViewController(refreshController: refreshController)
		refreshController.onRefresh = adaptFeedToCellControllers(forwardingTo: feedController, loader: imageLoader)
		return feedController
	}

	private static func adaptFeedToCellControllers(forwardingTo controller: FeedViewController, loader: FeedImageDataLoader) -> ([FeedImage]) -> Void {
		return { [weak controller] feed in
			controller?.tableModel = feed.map { model in
				FeedImageCellController(model: model, imageLoader: loader)
			}
		}
	}
}
```

### NASA Gallery Adaptation

```swift
public final class GalleryUIComposer {
    private init() {}

    public static func galleryComposedWith(
        galleryLoader: GalleryLoader,
        imageLoader: GalleryImageDataLoader
    ) -> GalleryViewController {
        let refreshController = GalleryRefreshViewController(galleryLoader: galleryLoader)
        let galleryController = GalleryViewController(refreshController: refreshController)

        refreshController.onRefresh = adaptGalleryToCellControllers(
            forwardingTo: galleryController,
            imageLoader: imageLoader
        )

        return galleryController
    }

    private static func adaptGalleryToCellControllers(
        forwardingTo controller: GalleryViewController,
        imageLoader: GalleryImageDataLoader
    ) -> ([GalleryImage]) -> Void {
        return { [weak controller] gallery in
            controller?.cellControllers = gallery.map { model in
                GalleryImageCellController(model: model, imageLoader: imageLoader)
            }
        }
    }
}
```

### Key Differences from Essential Feed

1. **Naming**
   - Essential Feed: `FeedUIComposer`, `tableModel`
   - NASA Gallery: `GalleryUIComposer`, `cellControllers`

2. **Architecture remains identical**
   - Same composer pattern
   - Same adapter closure pattern
   - Same weak reference to prevent retain cycles

---

## Component #4: Refactored GalleryViewController

### Purpose
Simplified view controller that delegates to cell controllers instead of managing everything itself.

### Current NASA Gallery Code (Monolithic)

The current implementation in `GalleryViewController` has ~228 lines managing:
- Refresh control setup
- Gallery loading
- Diffable data source
- Image loading per cell
- Task management
- Prefetching
- Cancellation

### Refactored NASA Gallery Code (Delegating)

```swift
public final class GalleryViewController: UICollectionViewController {
    private var refreshController: GalleryRefreshViewController?

    var cellControllers = [GalleryImageCellController]() {
        didSet {
            applySnapshot()
        }
    }

    convenience init(refreshController: GalleryRefreshViewController) {
        self.init(collectionViewLayout: Self.makeLayout())
        self.refreshController = refreshController
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.register(GalleryImageCell.self, forCellWithReuseIdentifier: GalleryImageCell.reuseIdentifier)
        collectionView.delegate = self
        collectionView.prefetchDataSource = self
        collectionView.refreshControl = refreshController?.view

        refreshController?.refresh()
    }

    // MARK: - Snapshot

    private enum Section {
        case main
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, GalleryImageCellController>()
        snapshot.appendSections([.main])
        snapshot.appendItems(cellControllers, toSection: .main)
        dataSource?.applySnapshotUsingReloadData(snapshot)
    }

    // MARK: - UICollectionViewDataSource (via Diffable)

    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, GalleryImageCellController> = {
        UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, cellController in
            guard let self = self else { return UICollectionViewCell() }
            return cellController.view(in: collectionView, at: indexPath)
        }
    }()

    // MARK: - UICollectionViewDelegate

    public override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Cell controller already started loading in view() method
        // This delegate method is just for UIKit lifecycle tracking
    }

    public override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cellController(at: indexPath)?.cancelLoad()
    }

    // MARK: - Helpers

    private func cellController(at indexPath: IndexPath) -> GalleryImageCellController? {
        guard indexPath.row < cellControllers.count else { return nil }
        return cellControllers[indexPath.row]
    }

    // ... Layout code remains the same ...
}

// MARK: - UICollectionViewDataSourcePrefetching

extension GalleryViewController: UICollectionViewDataSourcePrefetching {
    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            cellController(at: indexPath)?.preload()
        }
    }

    public func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            cellController(at: indexPath)?.cancelLoad()
        }
    }
}
```

### Key Changes from Current Implementation

**Removed:**
- ❌ `loader` and `imageLoader` properties (moved to composer)
- ❌ `gallery: [GalleryImage]` array (replaced with `cellControllers`)
- ❌ `imageLoadingTasks` dictionary (moved to cell controllers)
- ❌ `load()` method (moved to refresh controller)
- ❌ `loadImage(for:into:at:)` method (moved to cell controller)
- ❌ Manual refresh control setup (now injected)
- ❌ Diffable data source with `GalleryImage` as identifier

**Added:**
- ✅ `refreshController` property (injected dependency)
- ✅ `cellControllers: [GalleryImageCellController]` array
- ✅ Simplified `viewDidLoad` (just wire up injected components)
- ✅ Diffable data source with `GalleryImageCellController` as identifier
- ✅ Delegate methods call `cellController.preload()` / `cancelLoad()`

**Benefits:**
- Single Responsibility: ViewController only orchestrates, doesn't implement
- Easier testing: Can test cell controller in isolation
- Better composition: Dependencies clear and explicit
- Follows Essential Feed patterns

---

## Component #5: GalleryImageCell Updates

### Required Change: Add Reuse Identifier

The cell controller needs to dequeue cells using a reuse identifier. Add this to `GalleryImageCell`:

```swift
@MainActor public final class GalleryImageCell: UICollectionViewCell {
    static let reuseIdentifier = "GalleryImageCell"

    // ... rest of implementation unchanged ...
}
```

### Hashable Conformance for GalleryImageCellController

To use cell controllers in a diffable data source, they need `Hashable`:

```swift
extension GalleryImageCellController: Hashable {
    static func == (lhs: GalleryImageCellController, rhs: GalleryImageCellController) -> Bool {
        lhs.model.id == rhs.model.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(model.id)
    }
}
```

**Note:** This assumes `GalleryImage` has an `id` property. If not, use `url` as the unique identifier.

---

## Component #6: Test Helper Organization (Optional Improvement)

### Current State
NASA Gallery has test helpers inline in `GalleryViewControllerTests.swift` (lines 548-736).

### Essential Feed Approach
Separate files for focused helpers:
- `UIImage+TestHelpers.swift` - Image creation utilities
- `UIControl+TestHelpers.swift` - Control simulation (pull to refresh, tap)
- `GalleryImageCell+TestHelpers.swift` - Cell-specific test DSL
- `GalleryViewController+TestHelpers.swift` - ViewController-specific test DSL
- `GalleryViewControllerTests+LoaderSpy.swift` - Spy implementations
- `GalleryViewControllerTests+Assertions.swift` - Assertion helpers

### Recommendation
**DEFER THIS** - Focus on core refactoring first. Test helper organization can be a follow-up refactoring.

---

## Test-by-Test Implementation Workflow

**CRITICAL: This is a REFACTORING, not TDD.**

Unlike other Essential Feed PRs, this one doesn't add new tests - it restructures production code while keeping all existing tests passing.

### Implementation Steps

1. **RUN ALL TESTS (Baseline)**
   - User runs existing test suite
   - All tests should PASS
   - This confirms our starting point

2. **CREATE: GalleryRefreshViewController**
   - Claude implements `GalleryRefreshViewController.swift`
   - Mirrors Essential Feed pattern with async/await
   - No tests change - not wired up yet

3. **CREATE: GalleryImageCellController**
   - Claude implements `GalleryImageCellController.swift`
   - Extracts image loading logic from GalleryViewController
   - Add `Hashable` conformance
   - No tests change - not wired up yet

4. **CREATE: GalleryUIComposer**
   - Claude implements `GalleryUIComposer.swift`
   - Wires up refresh controller + cell controllers
   - No tests change - not used yet

5. **UPDATE: GalleryImageCell**
   - Add `static let reuseIdentifier = "GalleryImageCell"`
   - No behavior change

6. **UPDATE: GalleryViewControllerTests (makeSUT)**
   - Change from:
     ```swift
     let sut = GalleryViewController(loader: loader, imageLoader: imageLoader)
     ```
   - To:
     ```swift
     let sut = GalleryUIComposer.galleryComposedWith(
         galleryLoader: loader,
         imageLoader: imageLoader
     )
     ```
   - This is the ONLY test change needed

7. **REFACTOR: GalleryViewController**
   - Remove old monolithic implementation
   - Replace with delegating implementation (using cell controllers)
   - Keep layout code unchanged

8. **RUN ALL TESTS (Verify)**
   - User runs test suite again
   - All tests should STILL PASS
   - If any fail, debug before proceeding

9. **COMMIT**
   - Commit the refactoring with clear message
   - Example: "Refactor GalleryViewController using Multi-MVC pattern"

### Important Notes

- **ALL existing tests should pass** - we're refactoring, not changing behavior
- **Only ONE test line changes** - the `makeSUT` composition
- **No new tests needed** - behavior is identical, just better structured
- **This is safe refactoring** - test coverage proves correctness

---

## Key Insights for tips.md

### Pattern: Cell Controller Pattern
**What:** Extract a controller class to manage ONE cell's entire lifecycle (configuration, loading, cancellation, retry).

**Why it's good:**
- Single Responsibility: Controller focuses only on one cell
- Testability: Can test cell logic in isolation without full ViewController
- Reusability: Same pattern works for UITableView and UICollectionView
- Composition: Easy to compose different cell types

**How to apply:**
```swift
// Before (monolithic)
class ViewController {
    func willDisplay(cell, at indexPath) {
        // 50 lines of image loading, retry, cancellation
    }
}

// After (cell controller)
class CellController {
    func view() -> Cell {
        // Configure and return cell
    }
    func preload() { }
    func cancelLoad() { }
}

class ViewController {
    var cellControllers: [CellController]
    func willDisplay(cell, at indexPath) {
        // Just delegate: cellController.view()
    }
}
```

---

### Pattern: Refresh Controller Separation
**What:** Extract refresh control logic into a dedicated controller.

**Why it's good:**
- Clear boundary: One controller = one UIControl
- Delegate pattern: Communicate via closure, not tight coupling
- Async-friendly: Easy to wrap async/await in @objc action methods

**Gotcha:** Remember to use `Task { @MainActor }` when calling async code from `@objc` action methods.

```swift
@objc func refresh() {
    view.beginRefreshing()

    Task { @MainActor in
        defer { view.endRefreshing() }
        let data = try await loader.load()
        onRefresh?(data)
    }
}
```

---

### Pattern: Composer for Dependency Management
**What:** Factory pattern that creates and wires up all controllers.

**Why it's good:**
- Single point of composition
- Clear dependency graph
- Public API: Only composer is public, controllers are internal
- Testability: Easy to inject test doubles

**Structure:**
```swift
public final class Composer {
    private init() {}  // Prevent instantiation

    public static func composed(dep1: Dep1, dep2: Dep2) -> MainController {
        let subController1 = SubController1(dep: dep1)
        let subController2 = SubController2(dep: dep2)
        let main = MainController(sub1: subController1, sub2: subController2)

        // Wire up delegates/closures
        subController1.onEvent = { [weak main] data in
            main?.handle(data)
        }

        return main
    }
}
```

---

### Technique: Adapter Closure Pattern
**What:** Use a closure to adapt between different interfaces without creating a separate class.

**Where seen:**
```swift
// Instead of creating FeedAdapter class:
class FeedAdapter {
    weak var controller: FeedViewController
    let imageLoader: ImageLoader

    func didLoad(_ feed: [FeedImage]) {
        controller?.tableModel = feed.map {
            CellController(model: $0, loader: imageLoader)
        }
    }
}

// Use a closure adapter:
refreshController.onRefresh = adaptFeedToCellControllers(
    forwardingTo: controller,
    loader: imageLoader
)

private static func adaptFeedToCellControllers(...) -> ([FeedImage]) -> Void {
    return { [weak controller] feed in
        controller?.tableModel = feed.map { CellController(...) }
    }
}
```

**Why it's good:**
- Less boilerplate than full adapter class
- Captures dependencies in closure
- Still maintains weak references to prevent cycles

---

### Async/Await Adaptation: Completion Handler → Task
**Pattern for bridging @objc to async:**

```swift
// Essential Feed (callback-based)
@objc func action() {
    service.fetch { result in
        self.handle(result)
    }
}

// NASA Gallery (async/await)
@objc func action() {
    Task { @MainActor in
        do {
            let data = try await service.fetch()
            self.handle(data)
        } catch {
            self.handleError(error)
        }
    }
}
```

**Key points:**
- `@objc` methods can't be `async`, so wrap in `Task`
- Use `@MainActor` to ensure UI updates on main thread
- `defer` is your friend for cleanup (like `endRefreshing()`)

---

### Testing Insight: Refactoring Requires No New Tests
**Principle:** If you refactor WITHOUT changing behavior, existing tests should still pass without modification.

**What changed in this PR:**
- Production code: Completely restructured (3 new classes)
- Tests: Changed only ONE line (the composition in `makeSUT`)

**Why this works:**
- Tests verify BEHAVIOR, not implementation
- As long as behavior is identical, tests prove correctness
- This is the power of test-driven refactoring

**Red flag:** If you need to rewrite tests during a refactoring, you're probably changing behavior, not just structure.

---

### Architecture: Progressive Disclosure of Complexity
**What:** Hide implementation details behind simple public APIs.

**Before:**
```swift
// User needs to know about loaders, refresh controllers, cell controllers
let refreshController = GalleryRefreshViewController(loader: loader)
let viewController = GalleryViewController(refreshController: refreshController)
refreshController.onRefresh = { ... }  // User must wire this up
```

**After:**
```swift
// User just provides dependencies, composer handles wiring
let viewController = GalleryUIComposer.galleryComposedWith(
    galleryLoader: loader,
    imageLoader: imageLoader
)
```

**Benefits:**
- Simpler API for clients
- Internal refactoring doesn't break clients
- Dependency graph is explicit but hidden

---

## Summary

### What This Refactoring Achieves

1. **Better separation of concerns** - Each controller has one job
2. **Improved testability** - Can test cell controller without full ViewController
3. **Clearer dependencies** - Composer makes dependency graph explicit
4. **Follows Essential Feed patterns** - Consistent architecture across projects
5. **No behavior changes** - All existing tests still pass

### Migration Checklist

- [ ] Create `GalleryRefreshViewController` (async/await adaptation)
- [ ] Create `GalleryImageCellController` (async/await + UICollectionView)
- [ ] Create `GalleryUIComposer` (factory pattern)
- [ ] Add `reuseIdentifier` to `GalleryImageCell`
- [ ] Add `Hashable` conformance to `GalleryImageCellController`
- [ ] Update `GalleryViewControllerTests.makeSUT` to use composer
- [ ] Refactor `GalleryViewController` to delegate to controllers
- [ ] Run tests - all should still pass
- [ ] Commit refactoring

### Next Steps

After this refactoring is complete, the NASA Gallery will have:
- ✅ Clean Multi-MVC architecture
- ✅ Cell controller pattern
- ✅ Composer pattern for dependency management
- ✅ Better separation of concerns
- ✅ Foundation for future UI features

**Optional follow-up refactorings:**
- Extract test helpers into separate files (like Essential Feed)
- Add memory leak tracking to tests
- Consider view/controller splitting for cells (if needed)

---

## References

- **Essential Feed PR #21:** https://github.com/essentialdevelopercom/essential-feed-case-study/pull/21
- **Pattern:** Cell Controller Pattern (Essential Developer)
- **Pattern:** Composer Pattern (Gang of Four)
- **Technique:** Adapter Closure (functional programming)
- **Architecture:** Multi-MVC (Separated Responsibilities)
