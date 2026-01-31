# TheDriver (iOS / SwiftUI / TCA)

This repo is an iOS app built with SwiftUI + The Composable Architecture (TCA) and modularized with SwiftPM packages under `Packages/`.

## Where Code Goes
- App entry point (Xcode target): `Application/Sources/App.swift`
- App composition (tabs/root feature): `Packages/App/Sources/*`
- Simulator features + simulator side effects: `Packages/Simulator/Sources/*`
- Shared foundation: `Packages/Platform/Sources/*`
  - Shared models: `Packages/Platform/Sources/Entities/*`
  - Design system tokens: `Packages/Platform/Sources/DesignSystem/DesignTokens.swift`
  - Feature import layer (re-exports): `Packages/Platform/Sources/FeatureCore/FeatureCore.swift`

If you need to add a new feature/module, prefer adding it as a SwiftPM target under `Packages/*` (not directly into the Xcode app target).

## Build / Verify
- Build (CLI): `xcodebuild -project TheDriver.xcodeproj -scheme TheDriver -configuration Debug build`
- The app scheme is `TheDriver`.

## Architecture (TCA)

### Feature Template (Canonical)
- Feature reducers are `*Feature.swift` and use TCA macros:
  - `@Reducer public struct XFeature { ... }`
  - `@ObservableState public struct State: Equatable { ... }`
  - `@CasePathable public enum Action { ... }`
- Parent features compose children via `Scope`.

References:
- Root feature composition: `Packages/App/Sources/App/AppFeature.swift`
- Tab composition + scoping pattern: `Packages/App/Sources/MainTab/MainTabFeature.swift`

### View Actions & Bindings
- Use `ViewAction` with a nested `Action.View` enum for user-driven events.
- Use `BindableAction` + `BindingReducer()` only when the view needs bindings to state.

Reference:
- `Packages/App/Sources/MainTab/MainTabFeature.swift`

### Imports / Layering
- Feature modules should import `FeatureCore` instead of importing `ComposableArchitecture`, `Entities`, or `DesignSystem` directly.

Reference:
- `Packages/Platform/Sources/FeatureCore/FeatureCore.swift`

## Side Effects & Dependencies (swift-dependencies)

### Client Template (Canonical)
- Side effects live behind a client type annotated with `@DependencyClient`.
- The client API surface is declared in `Client.swift`.
- Live wiring is implemented via `DependencyKey` in `Live.swift`.

References:
- Client API: `Packages/Simulator/Sources/SimulatorClient/Client.swift`
- Live implementation: `Packages/Simulator/Sources/SimulatorClient/Live.swift`

## Design System
- Use `DesignTokens` for colors/typography/spacing/radius.
- Avoid raw literal `Color(...)` and ad-hoc spacing constants in feature views.

Reference:
- `Packages/Platform/Sources/DesignSystem/DesignTokens.swift`

## Naming & Style Conventions
- Prefer `...URL`/`...ID` casing in identifiers (e.g., `baseURL`, `someID`) instead of `...Url`/`...Id`.
- In SwiftUI view computed properties, avoid explicit `return`; use the view expression as the last line.
- Skip custom `Equatable` implementations when synthesized conformance is sufficient.
- User-facing UI strings should be written in Korean unless there is a strong reason not to.

## Lockfiles
- Authoritative SwiftPM lockfile for app builds:
  - `TheDriver.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`

## Do Not Touch / Do Not Commit
- Generated (SwiftPM build) output:
  - `Packages/**/.build/**`
  - `Packages/**/.swiftpm/**`
- User-local Xcode state:
  - `TheDriver.xcodeproj/xcuserdata/**`
  - `**/*.xcuserstate`

## Downlinks (Scoped Instructions)
- App entry & Xcode rules: `Application/AGENTS.md`
- App package rules: `Packages/App/AGENTS.md`
- Platform package rules: `Packages/Platform/AGENTS.md`
- Simulator package rules: `Packages/Simulator/AGENTS.md`

## Skills
- TCA conventions: `.opencode/skill/tca-the-driver/SKILL.md`
- Swift style: `.opencode/skill/swift-style-the-driver/SKILL.md`
- Xcode workflow + repo hygiene: `.opencode/skill/xcode-workflow-the-driver/SKILL.md`
