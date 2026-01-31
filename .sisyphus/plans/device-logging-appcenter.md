# DeviceLogging + AppCenter Shared Running App

## TL;DR

> **Quick Summary**: Add a Shared running-app state (TCA @Shared) so AppCenter sets the current app on run and DeviceLogging auto-starts an app-only log stream with a simple viewer and cancel.
>
> **Deliverables**:
> - Shared running-app model/key (bundleId, displayName, deviceId)
> - AppCenter sets Shared running app on run/launch
> - DeviceLogging shows pinned running app + streaming logs + cancel
> - App-only log filtering via simctl predicate (no new logging infra)
>
> **Estimated Effort**: Medium
> **Parallel Execution**: YES - 2 waves
> **Critical Path**: Shared model/key → AppCenter run wiring → DeviceLogging logging + UI

---

## Context

### Original Request
User wants logs displayed in DeviceLogging; when an app is run from AppCenter, store the running app via Shared; DeviceLogging should pin that app at the top, start logging for it, and allow cancel.

### Interview Summary
**Key Discussions**:
- Use TCA `@Shared` for running app state (new pattern in repo).
- Log scope is app-only.
- Shared running app data is minimal: bundleId + displayName + deviceId.
- Cancel stops logging only and keeps the shared selection.
- Verification is manual-only (no tests in repo).

**Research Findings**:
- DeviceLogging currently streams logs via `SimulatorClient.startLogging` and prints to console; UI is empty.
- `SimulatorClient` Live uses `xcrun simctl log stream` via `LogStreamer`.
- AppCenter currently installs only; `launchApp` exists in `SimulatorClient` but is unused.
- No existing `@Shared` usage in the codebase; app state is composed in `MainTabFeature`.

### Metis Review
**Identified Gaps (addressed)**:
- Define "DeviceLogging active" via view lifecycle (`onAppear`/`onDisappear`).
- Clarify cancel behavior: stop logging only (no auto-restart unless app changes).
- Implement app-only filtering via simctl predicate using bundleId.

---

## Work Objectives

### Core Objective
Create a minimal, reliable log viewer that auto-streams app-only logs for the current running app selected in AppCenter, using TCA Shared state.

### Concrete Deliverables
- New shared `RunningApp` model with bundleId, displayName, deviceId
- `@Shared` running app in AppCenter + DeviceLogging state
- AppCenter run flow sets Shared after successful launch
- DeviceLogging log list UI with pinned app header + cancel button
- App-only log filtering with simctl predicate (no new infra)

### Definition of Done
- AppCenter run sets Shared running app and DeviceLogging shows it at the top
- DeviceLogging starts log stream automatically and shows log lines
- Cancel stops stream and keeps Shared selection
- Build succeeds locally with `xcodebuild`

### Must Have
- Use TCA `@Shared` (user requested)
- App-only log stream (no full-device logs)

### Must NOT Have (Guardrails)
- No new logging infrastructure or new streamer types
- No persistence, export, search, or filtering UI
- No unrelated AppCenter or device management changes

---

## Verification Strategy (Manual-only)

### Test Decision
- **Infrastructure exists**: NO
- **User wants tests**: NO (manual-only)
- **Framework**: none

### Manual Verification (agent or human)
- Build: `xcodebuild -project TheDriver.xcodeproj -scheme TheDriver -configuration Debug build` → expect `** BUILD SUCCEEDED **`
- Run app and verify UI flow:
  1. Open the app and go to App Center tab.
  2. Import an app bundle, select a device, run/launch.
  3. Switch to Device Logging tab.
  4. Confirm running app header is shown with name + device.
  5. Confirm logs start streaming.
  6. Tap Cancel → logs stop; selection remains pinned.

---

## Execution Strategy

### Parallel Execution Waves

Wave 1 (Start Immediately):
├── Task 1: Add RunningApp model + Shared key
└── Task 2: Extend SimulatorClient logging to support app-only predicate

Wave 2 (After Wave 1):
├── Task 3: AppCenter run flow + set Shared running app
└── Task 4: DeviceLogging state + logging lifecycle using Shared

Wave 3 (After Wave 2):
└── Task 5: DeviceLogging UI (pinned app + logs + cancel)

Critical Path: Task 1 → Task 3 → Task 4 → Task 5

### Dependency Matrix

| Task | Depends On | Blocks | Can Parallelize With |
|------|------------|--------|----------------------|
| 1 | None | 3, 4 | 2 |
| 2 | None | 4 | 1 |
| 3 | 1 | 4, 5 | 2 |
| 4 | 1, 2 | 5 | 3 |
| 5 | 4 | None | None |

### Agent Dispatch Summary

| Wave | Tasks | Recommended Agents |
|------|-------|-------------------|
| 1 | 1, 2 | delegate_task(category="unspecified-high", load_skills=["tca-the-driver", "swift-style-the-driver"], run_in_background=true) |
| 2 | 3, 4 | delegate_task(category="unspecified-high", load_skills=["tca-the-driver", "swift-style-the-driver"], run_in_background=true) |
| 3 | 5 | delegate_task(category="visual-engineering", load_skills=["tca-the-driver", "swift-style-the-driver"], run_in_background=false) |

---

## TODOs

- [x] 1. Add Shared running-app model and key

  **What to do**:
  - Add a `RunningApp` model with `bundleId`, `displayName`, `deviceId` (Sendable/Equatable).
  - Define a TCA Shared key for `RunningApp?` (optional) accessible to features.
  - Validate `@Shared` is supported by the repo's TCA version; if not, stop and revert to app-level shared state (report back).

  **Must NOT do**:
  - Do not introduce persistence or storage outside of TCA Shared state.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: New shared-state pattern and cross-module type addition.
  - **Skills**: `tca-the-driver`, `swift-style-the-driver`
    - `tca-the-driver`: Ensures TCA macro and shared-state conventions.
    - `swift-style-the-driver`: Consistent Swift style in shared models.
  - **Skills Evaluated but Omitted**:
    - `frontend-ui-ux`: Not needed for model/key definition.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Task 2)
  - **Blocks**: 3, 4
  - **Blocked By**: None

  **References**:
  - `Packages/Platform/Sources/Entities/AppBundle.swift#L3` - Existing shared model style (Equatable/Sendable, small struct).
  - `Packages/Platform/Sources/FeatureCore/FeatureCore.swift#L1` - FeatureCore re-exports ComposableArchitecture for `@Shared` usage.

  **Acceptance Criteria**:
  - [ ] New `RunningApp` model exists with required fields.
  - [ ] Shared key defined and accessible to features.
  - [ ] `rg -n "@Shared" Packages` shows only the intended new usages.

- [x] 2. Extend SimulatorClient logging to support app-only predicate

  **What to do**:
  - Update `SimulatorClient.startLogging` to accept optional app predicate or bundleId.
  - Thread predicate into `LogStreamer.start` arguments using `--predicate`.
  - Use bundleId-based predicate (default: `subsystem == "<bundleId>"`).

  **Must NOT do**:
  - Do not add new logging clients or alternate streamers.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Client API change impacts multiple call sites.
  - **Skills**: `tca-the-driver`, `swift-style-the-driver`
    - `tca-the-driver`: Dependency client conventions.
    - `swift-style-the-driver`: Swift concurrency and API style.
  - **Skills Evaluated but Omitted**:
    - `frontend-ui-ux`: Not relevant.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Task 1)
  - **Blocks**: 4
  - **Blocked By**: None

  **References**:
  - `Packages/Clients/Sources/SimulatorClient/Client.swift#L5` - Current `startLogging` signature.
  - `Packages/Clients/Sources/SimulatorClient/Live.swift#L35` - `LogStreamer.start` arguments; predicate comment exists.

  **Acceptance Criteria**:
  - [ ] `startLogging` accepts a predicate/bundleId without breaking other calls.
  - [ ] LogStreamer uses `--predicate` when provided.
  - [ ] `rg -n "startLogging\(" Packages` shows updated call sites.

- [x] 3. AppCenter run flow sets Shared running app

  **What to do**:
  - Add `@Shared` running app to `AppCenterFeature.State`.
  - Update the run action to install (if needed), then launch via `SimulatorClient.launchApp`.
  - After successful launch, set Shared running app using bundleId/name/deviceId.
  - Update button label to reflect behavior (default: "설치 및 실행").

  **Must NOT do**:
  - Do not add new screens or device selection UX beyond existing flow.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: TCA reducer changes + async side effects.
  - **Skills**: `tca-the-driver`, `swift-style-the-driver`
    - `tca-the-driver`: ViewAction + effect patterns.
    - `swift-style-the-driver`: Async effect style.
  - **Skills Evaluated but Omitted**:
    - `frontend-ui-ux`: Minimal UI change only.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Task 4)
  - **Blocks**: 4, 5
  - **Blocked By**: 1

  **References**:
  - `Packages/Feature/Sources/AppCenter/AppCetnerFeature.swift#L99` - `installTapped` effect structure.
  - `Packages/Feature/Sources/AppCenter/Components/AppBundleCell.swift#L82` - install button UI and label.
  - `Packages/Clients/Sources/SimulatorClient/Client.swift#L7` - `launchApp` API signature.
  - `Packages/Platform/Sources/Entities/AppBundle.swift#L3` - bundleId and app name fields.

  **Acceptance Criteria**:
  - [ ] Running app Shared state is set after a successful launch.
  - [ ] Button label reflects install+run behavior.
  - [ ] Launch failures show toast and do not set Shared.

- [x] 4. DeviceLogging logging lifecycle using Shared running app

  **What to do**:
  - Add `@Shared` running app to `DeviceLoggingFeature.State`.
  - Add state for log lines and logging status (isLogging, isPaused).
  - On `onAppear`, auto-start logging for Shared app if not paused.
  - On `onDisappear`, stop logging to avoid background streams.
  - Append log lines to state and cap log list length (e.g., last 500 lines).
  - Cancel action stops logging but keeps Shared selection; auto-restart only when Shared changes.

  **Must NOT do**:
  - Do not start logging if Shared running app is nil.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: State/effect changes with shared state + lifecycle rules.
  - **Skills**: `tca-the-driver`, `swift-style-the-driver`
    - `tca-the-driver`: Reducer structure and effects.
    - `swift-style-the-driver`: State modeling and concurrency.
  - **Skills Evaluated but Omitted**:
    - `frontend-ui-ux`: View changes handled in Task 5.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Task 3)
  - **Blocks**: 5
  - **Blocked By**: 1, 2

  **References**:
  - `Packages/Feature/Sources/DeviceLogging/DeviceLoggingFeature.swift#L6` - Current state/actions structure.
  - `Packages/Feature/Sources/DeviceLogging/DeviceLoggingFeature.swift#L78` - Current log stream handling.
  - `Packages/App/Sources/MainTab/MainTabView.swift#L15` - DeviceLogging view lifecycle via tab.

  **Acceptance Criteria**:
  - [ ] Shared running app triggers auto-start on appear.
  - [ ] Cancel stops stream and prevents auto-restart until Shared changes.
  - [ ] Log list appends and caps without crashing or growing unbounded.

- [x] 5. DeviceLogging UI: pinned app + log viewer + cancel

  **What to do**:
  - Build a simple header showing running app name + device id and logging state.
  - Provide a Cancel button that dispatches stop action.
  - Display logs in a scrolling list; auto-scroll to newest log.
  - Show empty state when no Shared app is set.

  **Must NOT do**:
  - Do not add search/filter/export UI.

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
    - Reason: SwiftUI layout + log viewer behavior.
  - **Skills**: `tca-the-driver`, `swift-style-the-driver`
    - `tca-the-driver`: ViewAction wiring.
    - `swift-style-the-driver`: SwiftUI style consistency.
  - **Skills Evaluated but Omitted**:
    - `frontend-ui-ux`: Not required for simple in-app UI.

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 3
  - **Blocks**: None
  - **Blocked By**: 4

  **References**:
  - `Packages/Feature/Sources/DeviceLogging/DeviceLoggingView.swift#L12` - Empty view to replace with UI.
  - `Packages/Platform/Sources/DesignSystem/DesignTokens.swift` - Use tokens for spacing/color/typography.

  **Acceptance Criteria**:
  - [ ] Running app header is visible and updates with Shared state.
  - [ ] Log lines render in a scrolling list and auto-scroll to newest.
  - [ ] Cancel button stops log stream and disables streaming UI state.

---

## Commit Strategy

| After Task | Message | Files | Verification |
|------------|---------|-------|--------------|
| 1-2 | `feat(logging): add shared running app and log predicate` | Entities/FeatureCore/SimulatorClient files | `xcodebuild ... build` |
| 3-5 | `feat(logging): wire app run to shared logs UI` | AppCenter/DeviceLogging files | `xcodebuild ... build` |

---

## Success Criteria

### Verification Commands
```bash
xcodebuild -project TheDriver.xcodeproj -scheme TheDriver -configuration Debug build
```

### Final Checklist
- [x] Shared running app is set on AppCenter run
- [x] DeviceLogging shows running app pinned at top
- [x] App-only logs stream and stop on cancel
- [x] Build succeeds
