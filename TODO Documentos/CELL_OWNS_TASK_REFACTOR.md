# Cell-Owned Task Refactoring Plan

## Problem: Architectural Mismatch with Async/Await

### Current Architecture (ViewController owns Task)

**Issue**: The ViewController creates unstructured Tasks to load images, but the Cell receives only synchronous method calls. This creates a disconnect where tests can't naturally wait for async work to complete.

```swift
// ViewController - owns the async work
override func collectionView(..., willDisplay cell: ...) {
    cell.startLoading()  // Synchronous

    Task { @MainActor in  // ❌ ViewController's PRIVATE Task
        do {
            let data = try await task.value
            cell.display(image)
            cell.stopLoading()  // ❌ Cell has no visibility into when this happens
        } catch {
            cell.stopLoading()
            cell.showRetry()
        }
    }
}

// Cell - dumb, receives imperative commands
public func startLoading() {
    activityIndicator.startAnimating()
}

public func stopLoading() {
    activityIndicator.stopAnimating()
    onStopLoading?()  // ❌ Test hook needed!
}
```

**Testing Problem**: Tests need hooks because they can't wait for the ViewController's private Task:

```swift
@Test func showsLoadingIndicator() async {
    let cell = sut.simulateGalleryImageViewVisible(at: 0)
    #expect(cell?.isLoading == true)

    // ❌ Must use hook to wait for ViewController's Task to finish
    await withCheckedContinuation { continuation in
        cell?.onStopLoading = { continuation.resume() }
        imageLoader.completeImageLoading(with: Data(), at: 0)
    }

    #expect(cell?.isLoading == false)
}
```

---

## Solution: Cell Owns Its Async Loading Lifecycle

### Key Insight
**The Cell should own the Task that loads its image**, just like it owns its `imageView`, `titleLabel`, and other components. This makes the cell self-contained and testable.

### New Architecture

```swift
// Cell - smart, manages its own async loading
@MainActor public final class GalleryImageCell: UICollectionViewCell {
    public let imageView = UIImageView()
    public let titleLabel = UILabel()
    public let activityIndicator = UIActivityIndicatorView(style: .medium)
    public let retryButton = UIButton(type: .system)

    private var loadingTask: Task<Void, Never>?  // ✅ Cell owns its Task

    // ✅ Single public API - handles everything internally
    public func loadImage(from task: GalleryImageDataLoaderTask) {
        loadingTask = Task { @MainActor in
            startLoading()
            defer { stopLoading() }

            do {
                let data = try await task.value
                guard !Task.isCancelled else { return }

                if let image = UIImage(data: data) {
                    display(image)
                }
            } catch {
                guard !Task.isCancelled else { return }
                showRetry()
            }
        }
    }

    // ✅ Public API for tests - no hooks needed!
    public func waitForLoadingToComplete() async {
        await loadingTask?.value
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        loadingTask?.cancel()  // ✅ Cell manages its own cancellation
        imageView.image = nil
        titleLabel.text = nil
        stopLoading()
        hideRetry()
    }

    // MARK: - Private UI updates

    private func startLoading() {
        activityIndicator.startAnimating()
        bringSpinnerToFront()
    }

    private func stopLoading() {
        activityIndicator.stopAnimating()
    }

    private func showRetry() {
        retryButton.isHidden = false
    }

    private func hideRetry() {
        retryButton.isHidden = true
    }

    private func display(_ image: UIImage) {
        imageView.image = image
    }

    func apply(model: GalleryImage) {
        titleLabel.text = model.title
    }
}
```

```swift
// ViewController - simplified, just delegates
public override func collectionView(_ collectionView: UICollectionView,
                                   willDisplay cell: UICollectionViewCell,
                                   forItemAt indexPath: IndexPath) {
    guard let cell = cell as? GalleryImageCell,
          let imageLoader = imageLoader,
          indexPath.row < gallery.count else { return }

    let galleryImage = gallery[indexPath.row]

    // ✅ Check if we have a prefetched task
    let task: GalleryImageDataLoaderTask
    if let existingTask = imageLoadingTasks[indexPath] {
        task = existingTask
    } else {
        task = imageLoader.loadImageData(from: galleryImage.url)
        imageLoadingTasks[indexPath] = task
    }

    // ✅ Just tell the cell to load - it handles everything!
    cell.loadImage(from: task)
}

public override func collectionView(_ collectionView: UICollectionView,
                                   didEndDisplaying cell: UICollectionViewCell,
                                   forItemAt indexPath: IndexPath) {
    // ✅ Cell already cancelled in prepareForReuse, just clean up reference
    imageLoadingTasks[indexPath] = nil
}
```

---

## Benefits

| Aspect | Before (VC owns Task) | After (Cell owns Task) |
|--------|----------------------|------------------------|
| **Separation of Concerns** | ❌ VC manages cell's loading state | ✅ Cell is self-contained |
| **Testability** | ❌ Need hooks (`onStopLoading`) | ✅ Just `await cell.waitForLoadingToComplete()` |
| **Cancellation** | ❌ VC must track & cancel tasks | ✅ Cell auto-cancels in `prepareForReuse` |
| **Code Location** | ❌ Split: VC has async logic, Cell has UI | ✅ All loading logic in Cell |
| **Complexity** | ❌ Two-way coordination | ✅ One-way delegation |
| **SwiftUI-like** | ❌ Imperative (start/stop commands) | ✅ Declarative (`.task { }` style) |

---

## Clean Test Example

```swift
@Test func galleryImageView_showsLoadingIndicatorWhileLoadingImage() async {
    let fixture0 = makeGalleryImageFixture(urlString: "https://url-0.com")
    let (sut, loader, imageLoader) = makeSUT()
    loader.stub(gallery: [fixture0])

    sut.simulateAppearance()
    await sut.waitForRefreshToEnd()

    let cell = sut.simulateGalleryImageViewVisible(at: 0)

    // DURING loading
    #expect(cell?.isLoading == true)

    // Complete the loading
    imageLoader.completeImageLoading(with: Data(), at: 0)

    // ✅ NO HOOKS! Just await the cell's public API
    await cell?.waitForLoadingToComplete()

    // AFTER loading
    #expect(cell?.isLoading == false)
}

@Test func galleryImageView_displaysRetryOnImageLoadError() async {
    let fixture0 = makeGalleryImageFixture(urlString: "https://url-0.com")
    let (sut, loader, imageLoader) = makeSUT()
    loader.stub(gallery: [fixture0])

    sut.simulateAppearance()
    await sut.waitForRefreshToEnd()

    let cell = sut.simulateGalleryImageViewVisible(at: 0)

    // Complete with error
    imageLoader.completeImageLoadingWithError(at: 0)

    // ✅ NO HOOKS! Just await the cell
    await cell?.waitForLoadingToComplete()

    // Verify retry button is shown
    #expect(cell?.isShowingRetry == true)
}
```

---

## Alignment with Swift Concurrency Best Practices

From `CLAUDE.md`:

> **Storing and Cancelling Tasks - Basic Pattern for UIKit Cells:**
> ```swift
> class ImageCell: UICollectionViewCell {
>     private var loadingTask: Task<Void, Never>?
>
>     override func prepareForReuse() {
>         super.prepareForReuse()
>         loadingTask?.cancel()
>         imageView.image = nil
>     }
>
>     func configure(with url: URL) {
>         loadingTask = Task {
>             let image = await loadImage(from: url)
>             guard !Task.isCancelled else { return }
>             imageView.image = image
>         }
>     }
> }
> ```
> **Key Points**:
> - Store task reference as `Task<Void, Never>?`
> - Cancel in `prepareForReuse()` to prevent image flickering
> - Check `Task.isCancelled` before updating UI after async work

✅ This refactor follows these best practices exactly!

---

## Implementation Checklist

When ready to implement:

- [ ] Add `private var loadingTask: Task<Void, Never>?` to `GalleryImageCell`
- [ ] Add `public func loadImage(from task: GalleryImageDataLoaderTask)` to Cell
- [ ] Add `public func waitForLoadingToComplete() async` to Cell
- [ ] Make `startLoading()`, `stopLoading()`, `showRetry()`, `display()` private
- [ ] Update `prepareForReuse()` to cancel `loadingTask`
- [ ] Simplify `GalleryViewController.collectionView(_:willDisplay:)` to just call `cell.loadImage()`
- [ ] Remove `onStopLoading` and `onShowRetry` hooks from Cell
- [ ] Update all tests to use `await cell.waitForLoadingToComplete()` instead of hooks
- [ ] Run tests to verify everything still works
- [ ] Commit with message: "Refactor: Move image loading Task ownership to Cell"

---

## Future: Tiny MVC Components

This refactor aligns perfectly with a **Tiny MVC** architecture where each cell is a self-aware component:

- **Model**: `GalleryImage` (data to display)
- **View**: UIImageView, UILabel, UIButton (presentation)
- **Controller**: The Cell itself (coordinates loading, updates, cancellation)

Each cell becomes a mini-MVC that:
- ✅ Knows how to load its own data
- ✅ Manages its own loading state
- ✅ Handles its own cancellation
- ✅ Exposes a clean, testable API

The ViewController becomes a **coordinator** that just:
- Manages the collection view
- Provides data sources and loaders
- Delegates work to cells

---

## References

- Essential Feed PR #20: https://github.com/essentialdevelopercom/essential-feed-case-study/pull/20/commits/b56d0b9e04729b9894fad6089e060912831cdc46
- Key insight: Callback-based architecture has simpler tests because completion handlers execute synchronously. Async/await requires cells to own their Tasks for testability.
