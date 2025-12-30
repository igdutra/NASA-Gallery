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
