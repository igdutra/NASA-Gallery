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
