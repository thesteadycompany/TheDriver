---
name: swift-style-the-driver
description: Swift style and organization conventions inferred from TheDriver.
---

## Use this when
- Writing new Swift files.
- Exposing public API from a SwiftPM target.
- Adding concurrency and error handling.

## Access Control
- Public APIs are explicitly `public`.
- Internal app-only types generally omit access control (default internal).
- Use `fileprivate` for file-scoped helpers when needed.

References:
- Public API + nested types: `Packages/Simulator/Sources/SimulatorClient/Client.swift`
- file-scoped helper style: `Packages/Simulator/Sources/DeviceList/Components/DeviceStateBadge.swift`

## File Organization
- One primary type per file.
- Supporting types often live in extensions in the same file.
- Features and views are separated (`*Feature.swift` vs `*View.swift`).

Reference:
- `Packages/App/Sources/App/AppFeature.swift`

## Concurrency & Errors
- Prefer `async`/`await` and `throws` for effectful APIs.
- Bridging to callback-style APIs can use continuations.

Reference:
- `Packages/Simulator/Sources/SimulatorClient/Live.swift`

## Do / Don't
- Do: keep APIs `Sendable` where appropriate (client layer).
- Do: use `throws` rather than `Result` unless an API requires otherwise.
- Do: in SwiftUI view builders (computed properties and `-> some View` helpers), omit explicit `return` and make the view expression the final line.
- Don't: add custom formatting/lint rules in-repo unless explicitly requested.
