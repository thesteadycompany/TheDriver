# Packages/App

This package owns the app-level composition (root feature + tabs).

## Composition Rules
- Keep app composition in reducers; avoid introducing alternate architectures.
- Use `Scope` to wire child features.
- Keep root content mounted and present setup flows (onboarding/permissions) with sheet/overlay when possible.

References:
- Root composition: `Packages/App/Sources/App/AppFeature.swift`
- Tabs + scoping: `Packages/App/Sources/MainTab/MainTabFeature.swift`

## View ↔ Reducer Conventions
- User events go through `Action.View` (ViewAction).
- Binding is only for view-bound state: `Action.binding` + `BindingReducer()`.
- Child-to-parent events should use `Action.Delegate`; avoid matching child `Action.Local` directly in parent reducers.
- Keep `Reduce` thin: route actions into helper functions such as `child(...)`/`view(...)`.
- Name helper functions concisely by domain (`onboarding`) and avoid redundant suffixes like `onboardingChild`.
- Prefer explicit/exhaustive `switch`es and avoid `default` unless truly necessary.

Reference:
- `Packages/App/Sources/MainTab/MainTabFeature.swift`

## Related Skills
- `.opencode/skill/tca-the-driver/SKILL.md`
