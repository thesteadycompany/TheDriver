---
name: xcode-workflow-the-driver
description: How to build/verify TheDriver and avoid generated/user-local file pitfalls.
---

## Use this when
- You need to verify a change compiles.
- You are adding/modifying SwiftPM targets under `Packages/`.
- You are unsure which `Package.resolved` matters.

## Build
- Command: `xcodebuild -project TheDriver.xcodeproj -scheme TheDriver -configuration Debug build`

## Lockfiles
- Authoritative lockfile for app builds:
  - `TheDriver.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`

## Xcode vs SwiftPM Boundaries
- App bootstrap lives in `Application/`.
- App features and shared modules live under `Packages/`.
- Prefer adding new code as SwiftPM targets under `Packages/*`.

## Package.swift Target Ordering
- In `Packages/*/Package.swift`, keep `targets` grouped and sorted:
  - `.target(...)` entries first, alphabetically.
  - `.testTarget(...)` entries next, alphabetically.
- When adding a new feature or client target, add/update the corresponding test target in the same change where possible.

## Do Not Touch / Do Not Commit
- Generated:
  - `Packages/**/.build/**`
  - `Packages/**/.swiftpm/**`
- User-local:
  - `TheDriver.xcodeproj/xcuserdata/**`
  - `**/*.xcuserstate`

## References
- App entry: `Application/Sources/App.swift`
- SwiftPM packages: `Packages/*/Package.swift`
