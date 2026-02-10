# Packages/Feature

This package owns features.

## Feature Conventions
- Follow the repo TCA feature template.
- Keep user-facing UI strings in Korean unless there is a strong reason not to.

## Package.swift Ordering
- In `Packages/Feature/Package.swift`, list all `.target(...)` entries first in alphabetical order.
- After all regular targets, list `.testTarget(...)` entries in alphabetical order.
- When adding a feature target, add its corresponding test target in the same change.

Reference:
- `Packages/Feature/Sources/DeviceList/DeviceListFeature.swift`

## Related Skills
- `.opencode/skill/tca-the-driver/SKILL.md`
- `.opencode/skill/xcode-workflow-the-driver/SKILL.md`
