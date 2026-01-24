# Packages/Platform

This package is the shared foundation for the whole app.

## Module Boundaries
- `Entities` is the source of truth for shared domain models.
- `DesignSystem` owns design tokens.
- `FeatureCore` exists to re-export common feature-layer imports.

References:
- `Packages/Platform/Sources/Entities/*`
- `Packages/Platform/Sources/DesignSystem/DesignTokens.swift`
- `Packages/Platform/Sources/FeatureCore/FeatureCore.swift`

## Import Policy
- Feature modules should import `FeatureCore`.
- Client modules should prefer `ClientCore` (if available) rather than reaching into unrelated layers.

## Related Skills
- `.opencode/skill/swift-style-the-driver/SKILL.md`
