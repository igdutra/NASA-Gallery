# Project Instructions for Claude Code

## Running Tests

### macOS Tests (CI)
```bash
xcodebuild clean build test \
  -project NASAGallery/NASAGallery.xcodeproj/ \
  -scheme "CI-macOS" \
  -destination "platform=macOS,arch=arm64" \
  -testPlan "CI-macOS" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO
```

This command runs all tests in the CI-macOS test plan, which is used by the GitHub Actions CI pipeline.

### iOS Tests (CI)
```bash
xcodebuild clean build test \
  -project NASAGallery/NASAGallery.xcodeproj/ \
  -scheme "CI-iOS" \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  -testPlan "CI-iOS" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO
```

This command runs all tests in the CI-iOS test plan on the iOS Simulator. The CI uses `iPhone 16` with `OS=18.5`, but locally you can use any available simulator (e.g., `iPhone 17`).

**IMPORTANT for Claude Code**: When running these tests via the Bash tool:
- Use `run_in_background=true` parameter to run the command in the background
- DO NOT pipe output with `tee` or `tail` - this causes "Unknown build action" errors
- Use the `BashOutput` tool with the shell ID to monitor test results
- Filter BashOutput with regex pattern `(Test Suite|Test Case|passed|failed|BUILD SUCCEEDED)` to see test results

Example:
```
Bash tool with:
- command: xcodebuild clean build test -project NASAGallery/NASAGallery.xcodeproj/ -scheme "CI-iOS" -sdk iphonesimulator -destination "platform=iOS Simulator,name=iPhone 17" -testPlan "CI-iOS" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
- run_in_background: true

Then use BashOutput tool to monitor results.
```

## Git Commits

When creating commit messages:
- Use clear, concise language describing what was changed
- DO NOT include "Co-Authored-By: Claude" or similar attribution
- DO NOT include emoji or "Generated with Claude Code" footers
- Keep commits focused and follow conventional commit style

## TDD Workflow

This project follows strict TDD (Test-Driven Development). For every feature:

### Step-by-Step Process:
1. **RED** - Write the test first
   - Write test that describes the desired behavior
   - Add any necessary test helpers/spies
   - User runs tests to confirm they FAIL
   - DO NOT proceed until user confirms RED

2. **GREEN** - Write minimal implementation
   - Write the simplest code to make the test pass
   - Focus on making it work, not making it perfect
   - User runs tests to confirm they PASS
   - DO NOT proceed until user confirms GREEN

3. **COMMIT** - Commit immediately when GREEN
   - Commit as soon as tests pass
   - Use clear, descriptive commit message
   - DO NOT batch multiple features into one commit

4. **ASK** - Ask before proceeding to next test
   - Always ask user before writing the next test
   - User may want to review, refactor, or change direction
   - DO NOT automatically proceed to the next feature

### Important Rules:
- NEVER skip the RED phase - always confirm tests fail first
- NEVER commit before tests are GREEN
- ALWAYS commit immediately after tests pass
- ALWAYS ask user before proceeding to next test
- User runs all tests (Claude does not run test commands)

## Swift Task Capture and Cancellation Patterns

This section documents best practices for working with Swift's `Task` type, specifically around capturing, storing, and cancelling them properly.

### Cooperative Cancellation Model

Swift Concurrency uses a **cooperative cancellation** model. This means:
- Calling `task.cancel()` does NOT stop the task immediately
- It only sets a cancellation flag that the task can check
- It is YOUR responsibility to check for cancellation and stop work gracefully

### Checking for Cancellation

Two methods to check cancellation status:

```swift
// Method 1: Throws CancellationError if cancelled
try Task.checkCancellation()

// Method 2: Boolean check for conditional logic
guard !Task.isCancelled else {
    return cachedResults  // Return partial/cached data
}
```

**Best Practice**: Place `Task.checkCancellation()` after each await point to avoid unnecessary work.

### Storing and Cancelling Tasks

#### Basic Pattern for UIKit Cells

```swift
class ImageCell: UICollectionViewCell {
    private var loadingTask: Task<Void, Never>?

    override func prepareForReuse() {
        super.prepareForReuse()
        loadingTask?.cancel()
        imageView.image = nil
    }

    func configure(with url: URL) {
        loadingTask = Task {
            let image = await loadImage(from: url)
            guard !Task.isCancelled else { return }
            imageView.image = image
        }
    }
}
```

**Key Points**:
- Store task reference as `Task<Void, Never>?`
- Cancel in `prepareForReuse()` to prevent image flickering
- Check `Task.isCancelled` before updating UI after async work

#### ViewController Pattern

```swift
class ImageViewController: UIViewController {
    private var loadingTask: Task<Void, Never>?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadingTask = Task {
            await loadData()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        loadingTask?.cancel()
    }
}
```

**Important**: Cancel in `viewWillDisappear`, NOT in `deinit`. For long-running tasks (like `for await` loops), `deinit` may never be called due to the retain cycle.

### Memory Management Considerations

#### When Strong Self is Safe
```swift
// Short-lived task - OK to use strong self
Task {
    let data = try await fetchData()
    self.updateUI(with: data)  // Safe: task completes quickly
}
```
Tasks release their captured values when they complete. For finite operations, strong `self` does not create permanent retain cycles.

#### When Weak Self is Required
```swift
// Long-running observation - MUST use weak self
Task { [weak self] in
    for await update in stream {
        guard let self else { return }
        self.handle(update)
    }
}
```
Use `[weak self]` for:
- Infinite loops (`for await` over AsyncSequence)
- Long-running observations
- Tasks that may outlive their owner

#### Property Extraction Pattern
```swift
// Extract needed properties to avoid retaining self
Task { [weak self, urlSession, imageURL] in
    let (data, _) = try await urlSession.data(from: imageURL)
    self?.displayImage(data)
}
```

### withTaskCancellationHandler

Use when you need to respond to cancellation while the task is suspended:

```swift
await withTaskCancellationHandler {
    // Your async operation
    await performWork()
} onCancel: {
    // Called immediately when task is cancelled
    // Useful for cleaning up non-cooperative work
    externalOperation.cancel()
}
```

**Use Cases**:
- Bridging callback-based APIs that don't support cooperative cancellation
- Cleaning up external resources when cancelled
- Implementing AsyncSequence with cancellation support

### AnyCancellable Pattern (Combine Integration)

If using Combine, leverage `AnyCancellable` for automatic cancellation:

```swift
extension Task {
    func store(in set: inout Set<AnyCancellable>) {
        set.insert(AnyCancellable(cancel))
    }
}

// Usage
class ViewModel {
    private var cancellables = Set<AnyCancellable>()

    func load() {
        Task {
            await fetchData()
        }.store(in: &cancellables)
    }
    // Tasks auto-cancel when cancellables is deallocated
}
```

### Structured vs Unstructured Tasks

| Type | Auto-Cancellation | Use Case |
|------|-------------------|----------|
| SwiftUI `.task` modifier | Yes, on view disappear | SwiftUI views |
| `async let` | Yes, on scope exit | Parallel child operations |
| `withTaskGroup` | Yes, on scope exit | Dynamic parallel work |
| `Task { }` | NO - manual | UIKit, callbacks, fire-and-forget |
| `Task.detached { }` | NO - manual | Independent background work |

### Best Practices Summary

1. **Always check cancellation** after each `await` before doing expensive work
2. **Store Task references** when you need to cancel later
3. **Cancel in `prepareForReuse`** for collection/table view cells
4. **Cancel in `viewWillDisappear`** for view controllers, not `deinit`
5. **Use `[weak self]`** for long-running or infinite tasks
6. **Strong self is fine** for short, finite operations
7. **Check `Task.isCancelled`** before updating UI after async work
8. **Use `withTaskCancellationHandler`** for non-cooperative cleanup

### References

- [WWDC21: Explore structured concurrency in Swift](https://developer.apple.com/videos/play/wwdc2021/10134/)
- [WWDC23: Beyond the basics of structured concurrency](https://developer.apple.com/videos/play/wwdc2023/10170/)
- [Swift by Sundell: Memory management when using async/await](https://www.swiftbysundell.com/articles/memory-management-when-using-async-await/)
- [Swift with Majid: Task Cancellation in Swift Concurrency](https://swiftwithmajid.com/2025/02/11/task-cancellation-in-swift-concurrency/)
- [Hacking with Swift: How to cancel a Task](https://www.hackingwithswift.com/quick-start/concurrency/how-to-cancel-a-task)
- [Donny Wals: Efficiently loading images in table views and collection views](https://www.donnywals.com/efficiently-loading-images-in-table-views-and-collection-views/)
- [Tanaschita: Understanding task cancellation and lifetimes](https://tanaschita.com/swift-async-tasks-cancellation/)
