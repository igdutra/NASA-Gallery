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
