---
name: tca-the-driver
description: TheDriver's canonical TCA feature and dependency patterns.
---

## Use this when
- Adding a new feature reducer/view.
- Wiring child features into a parent.
- Introducing a new user action or a view binding.
- Adding dependencies to a reducer.

## Canonical Feature Shape
- File naming:
  - Reducer: `XFeature.swift`
  - View: `XView.swift`
- Reducer structure:
  - `@Reducer public struct XFeature { ... }`
  - `@ObservableState public struct State: Equatable { ... }`
  - `@CasePathable public enum Action { ... }`
  - `public var body: some ReducerOf<Self> { ... }`

References:
- Minimal root feature pattern: `Packages/App/Sources/App/AppFeature.swift`
- Feature with bindings + child scoping: `Packages/App/Sources/MainTab/MainTabFeature.swift`

## View Actions
- Prefer `Action.View` for user events.
- Keep reducer logic split into `private func view(...)` / `private func child(...)` when it improves readability.

Reference:
- `Packages/App/Sources/MainTab/MainTabFeature.swift`

## Dependencies
- Use `@Dependency` inside reducer functions/cases.
- Prefer explicit client APIs (swift-dependencies) over calling system APIs directly from reducers.

References:
- Client API surface: `Packages/Simulator/Sources/SimulatorClient/Client.swift`
- Live wiring: `Packages/Simulator/Sources/SimulatorClient/Live.swift`

## Do / Don't
- Do: compose features via `Scope`.
- Do: keep side effects behind dependency clients.
- Don't: introduce alternate state management (MVVM rewrite, coordinators) unless requested.
- Don't: import `ComposableArchitecture` directly in feature modules; import `FeatureCore`.

## Quick Checklist
- New feature follows `State/Action/body` macros.
- Parent feature uses `Scope` for children.
- Views send actions through `Action.View` (and bindings only when needed).
- Side effects go through dependency clients.
