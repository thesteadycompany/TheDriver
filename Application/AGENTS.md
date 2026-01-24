# Application (Xcode app target)

This subtree contains the Xcode app entry point.

## App Bootstrap
- Keep `@main` and root `Store` initialization in `Application/Sources/App.swift`.
- The root store should be created with `Store(initialState:) { AppFeature() }`.

Reference:
- `Application/Sources/App.swift`

## Imports
- Prefer importing the `App` product for app features.
- Importing `FeatureCore` here is currently used (see `Application/Sources/App.swift`). If you add more imports, keep them minimal and consistent.

## Build
- Scheme: `TheDriver`
- Command: `xcodebuild -project TheDriver.xcodeproj -scheme TheDriver -configuration Debug build`

## Related Skills
- `.opencode/skill/xcode-workflow-the-driver/SKILL.md`
