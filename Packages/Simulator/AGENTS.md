# Packages/Simulator

This package owns simulator-oriented features and side effects (via `SimulatorClient`).

## Side Effects Policy
- Use swift-dependencies clients for side effects; avoid ad-hoc singletons.
- Keep process execution behind the client layer.

References:
- Client API: `Packages/Simulator/Sources/SimulatorClient/Client.swift`
- Live wiring + runner: `Packages/Simulator/Sources/SimulatorClient/Live.swift`

## Feature Conventions
- Follow the repo TCA feature template.

Reference:
- `Packages/Simulator/Sources/DeviceList/DeviceListFeature.swift`

## Known Risk
- `SimulatorClient` imports `Entities`/`Dependencies` directly in its source files; ensure target dependencies stay coherent when adding new imports.

## Related Skills
- `.opencode/skill/tca-the-driver/SKILL.md`
- `.opencode/skill/xcode-workflow-the-driver/SKILL.md`
