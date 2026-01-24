# Packages/App

This package owns the app-level composition (root feature + tabs).

## Composition Rules
- Keep app composition in reducers; avoid introducing alternate architectures.
- Use `Scope` to wire child features.

References:
- Root composition: `Packages/App/Sources/App/AppFeature.swift`
- Tabs + scoping: `Packages/App/Sources/MainTab/MainTabFeature.swift`

## View ↔ Reducer Conventions
- User events go through `Action.View` (ViewAction).
- Binding is only for view-bound state: `Action.binding` + `BindingReducer()`.

Reference:
- `Packages/App/Sources/MainTab/MainTabFeature.swift`

## Related Skills
- `.opencode/skill/tca-the-driver/SKILL.md`
