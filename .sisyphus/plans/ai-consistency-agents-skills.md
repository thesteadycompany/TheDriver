# AI Consistency: OpenCode AGENTS + Skills (TheDriver)

## Context

### Original Request
Analyze the current project and create OpenCode guidance files (AGENTS + SKILL) so future AI changes are consistent.

### Interview Summary
**Confirmed**:
- Target tool: OpenCode
- Language: English (primary)
- Consistency priorities: Architecture, Code Style, Workflow
- Workflow scope: Docs only (no lint/test/tooling setup)
- File locations:
  - Root `AGENTS.md`
  - Scoped `AGENTS.md` in key subtrees
  - `.opencode/skill/<name>/SKILL.md`

**Repo Facts (evidence)**:
- iOS/Swift project. Primary build entry is Xcode (`TheDriver.xcodeproj`). Local SwiftPM packages live under `Packages/`.
- Architecture patterns: SwiftUI + The Composable Architecture (TCA) + swift-dependencies.

### Research Findings
**OpenCode conventions**:
- Root `AGENTS.md` commonly holds repo-wide rules/commands; scoped `AGENTS.md` can be used for subtrees with downlinks.
- Skills commonly live under `.opencode/skill/<name>/SKILL.md` with YAML frontmatter and “Use this when”.

**TCA documentation norms**:
- Emphasize: single store, reducer composition, explicit effects, explicit dependencies.
- Dependency clients often add `DependencyValues` accessors and test/preview defaults (even if tests aren’t present yet).

### Metis Review
Metis consultation could not be executed due to a tool error (`delegate_task` with `subagent_type=metis` repeatedly failed to dispatch). A manual gap review is included in “Decisions Needed” and “Guardrails”.

---

## Work Objectives

### Core Objective
Create repo-specific OpenCode guidance (AGENTS + skills) that encodes TheDriver’s architecture, Swift style, and workflow conventions so future AI outputs converge on the same patterns.

### Concrete Deliverables
- `AGENTS.md`
- `Application/AGENTS.md`
- `Packages/App/AGENTS.md`
- `Packages/Platform/AGENTS.md`
- `Packages/Simulator/AGENTS.md`
- `.opencode/skill/tca-the-driver/SKILL.md`
- `.opencode/skill/swift-style-the-driver/SKILL.md`
- `.opencode/skill/xcode-workflow-the-driver/SKILL.md`

### Definition of Done
- The above files exist and are written in English.
- Each file contains repo-specific, actionable rules and commands (not generic advice).
- Guidance references real code paths in this repo for every major rule.

### Must Have
- A canonical TCA “feature template” (State/Action, ViewAction, Scopes, dependencies) anchored to existing code.
- A canonical “client template” for swift-dependencies (`@DependencyClient` + `Live.swift`).
- A documented module layering/import policy using `FeatureCore` re-exports.
- A documented build verification command (`xcodebuild`) and scheme name.
- Explicit “do not touch / do not commit” guidance for generated + user-local files.

### Must NOT Have (Guardrails)
- Don’t invent new architectures (no MVVM rewrite, no coordinators/routers) unless explicitly requested.
- Don’t introduce new tooling (SwiftLint/SwiftFormat/tests) as part of this work.
- Don’t prescribe patterns not present in-repo (navigation stacks, cancellables, persistence) as mandatory rules.

---

## Verification Strategy

### Test Decision
- Infrastructure exists: NO (no tests detected)
- User wants tests: NO (docs-only scope)

### Manual QA (docs)
- Verify files exist at the intended paths.
- Verify each file contains:
  - repo-specific “Do / Don’t”
  - at least 3 concrete file references showing the intended pattern
  - at least 1 concrete command (where relevant)

---

## Task Flow

1) Draft the repo-wide rules (root AGENTS)
2) Draft subtree-specific rules (scoped AGENTS)
3) Draft skills (TCA / Swift style / Xcode workflow)
4) Cross-link AGENTS ↔ skills, add downlinks
5) Final consistency pass (no contradictions, no generic fluff)

---

## TODOs

> Docs-only tasks still require concrete acceptance criteria.

### Progress Checklist
- [x] 0. Baseline repo map and invariants verified
- [x] 1. Root `AGENTS.md` created
- [x] 2. Scoped `AGENTS.md` files created
- [x] 3. `.opencode/skill/*/SKILL.md` files created
- [x] 4. Cross-links and consistency pass done
- [x] 5. Ambiguity decisions documented in `AGENTS.md`

### 0. Establish baseline repo map and invariants

**What to do**:
- Confirm the scheme name and the recommended build command are correct.
- Confirm the feature/client patterns referenced below still exist (no moved files).

**References**:
- `TheDriver.xcodeproj/xcuserdata/hogumachu.xcuserdatad/xcschemes/xcschememanagement.plist` - scheme `TheDriver` evidence
- `Packages/App/Sources/MainTab/MainTabFeature.swift` - TCA feature pattern
- `Packages/Simulator/Sources/SimulatorClient/Client.swift` - DependencyClient pattern

**Acceptance Criteria**:
- `xcodebuild -project TheDriver.xcodeproj -scheme TheDriver -configuration Debug build` succeeds
- All referenced files exist

### 1. Create root `AGENTS.md` (repo-wide)

**What to do**:
- Create `AGENTS.md` with:
  - Repo overview (iOS/SwiftUI/TCA, Xcode+SwiftPM)
  - “Where code goes” (Application vs Packages)
  - Module layering rules (FeatureCore imports, Entities ownership)
  - Workflow commands (build command, how to add a new package target)
  - Style baseline (access control, file naming conventions)
  - Safety guardrails (generated/user-local files, Package.resolved policy placeholder)
  - Links to scoped `AGENTS.md` and to `.opencode/skill/*`.

**Must NOT do**:
- Do not add lint/test setup steps.
- Do not state rules that contradict existing code.

**Parallelizable**: YES (with 2 and 3)

**Pattern References**:
- `Application/Sources/App.swift` - app bootstrap & store initialization pattern
- `Packages/App/Sources/App/AppFeature.swift` - `@Reducer` + `@ObservableState` baseline
- `Packages/App/Sources/MainTab/MainTabFeature.swift` - `ViewAction` + `BindingReducer` + `Scope`
- `Packages/Simulator/Sources/DeviceList/DeviceListFeature.swift` - dependency usage in reducer
- `Packages/Simulator/Sources/SimulatorClient/Client.swift` - `@DependencyClient` surface
- `Packages/Simulator/Sources/SimulatorClient/Live.swift` - live DI wiring
- `Packages/Platform/Sources/FeatureCore/FeatureCore.swift` - re-export and import strategy
- `Packages/Platform/Sources/DesignSystem/DesignTokens.swift` - design token usage

**Acceptance Criteria**:
- `AGENTS.md` exists and contains:
  - a build command
  - “Where to add code” section
  - “TCA feature template” short reference + link to skill
  - “Client template” short reference + link to skill
  - “Do not touch” list

### 2. Create scoped `AGENTS.md` for code ownership and local workflows

**What to do**:
- Create these scoped instruction files:
  - `Application/AGENTS.md`: app entry rules (Store init, allowed imports), Xcode scheme notes
  - `Packages/App/AGENTS.md`: app composition rules (tabs, feature wiring)
  - `Packages/Platform/AGENTS.md`: shared modules rules (Entities/DesignSystem/FeatureCore boundaries)
  - `Packages/Simulator/AGENTS.md`: client + simulator feature rules
- Each scoped file should:
  - downlink to the relevant skill(s)
  - list the canonical files to mimic

**Parallelizable**: YES (with 1 and 3)

**References**:
- `Packages/App/Package.swift` - App targets and dependencies
- `Packages/Platform/Package.swift` - Platform targets and re-exports
- `Packages/Simulator/Package.swift` - Simulator targets and dependencies

**Acceptance Criteria**:
- Each scoped file exists and includes:
  - at least 2 repo-specific rules
  - at least 2 file references
  - at least 1 “Must NOT do” guardrail

### 3. Create OpenCode skills under `.opencode/skill/*`

**What to do**:
- Add these skills (YAML frontmatter required):
  - `.opencode/skill/tca-the-driver/SKILL.md`
    - “Feature template” (naming, file layout, State/Action, View/Local, Scope, BindingReducer)
    - “Dependency usage” patterns (`@Dependency` in reducers)
  - `.opencode/skill/swift-style-the-driver/SKILL.md`
    - access control expectations (public API vs internal)
    - file organization patterns (1 main type per file, extensions)
    - concurrency style (async/await, throws)
  - `.opencode/skill/xcode-workflow-the-driver/SKILL.md`
    - build command and scheme
    - how to reason about Xcode vs SwiftPM boundaries
    - what files are generated/user-local and must not be edited

**Parallelizable**: YES (with 1 and 2)

**References (TCA)**:
- `Packages/App/Sources/MainTab/MainTabFeature.swift`
- `Packages/Simulator/Sources/DeviceList/DeviceListFeature.swift`
- `Packages/Simulator/Sources/SimulatorClient/Client.swift`
- `Packages/Simulator/Sources/SimulatorClient/Live.swift`

**References (Swift style)**:
- `Packages/Simulator/Sources/SimulatorClient/Client.swift` - public API + extensions
- `Packages/Simulator/Sources/SimulatorClient/Live.swift` - async/await + throws
- `Packages/Simulator/Sources/DeviceList/Components/DeviceStateBadge.swift` - fileprivate extension usage

**Acceptance Criteria**:
- Each SKILL file includes:
  - YAML frontmatter with `name` + `description`
  - “Use this when” section
  - “Do / Don’t” section
  - at least 3 repo file references

### 4. Resolve internal contradictions and add cross-links

**What to do**:
- Ensure root AGENTS links to all scoped AGENTS and skills.
- Ensure scoped AGENTS link back to skills.
- Ensure rules don’t conflict (e.g., import rules, where code lives).

**Parallelizable**: NO (depends on 1–3)

**Acceptance Criteria**:
- Every AGENTS file contains at least one link to a skill or a downlink.
- No rule contradicts actual referenced code patterns.

### 5. Document known ambiguity decisions

**What to do**:
- Add a short “Decisions & Rationale” section in `AGENTS.md` capturing:
  - How to treat multiple `Package.resolved` files (Xcode workspace is authoritative)
  - Whether `Application/Sources/App.swift` may import Platform modules directly (document current practice)
  - Whether `SimulatorClient` may import `Entities`/`Dependencies` directly vs via re-exports

**Parallelizable**: NO (depends on 1–4)

**References**:
- `Packages/App/Package.resolved`
- `Packages/Simulator/Package.resolved`
- `Packages/Platform/Package.resolved`
- `TheDriver.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`

**Acceptance Criteria**:
- `AGENTS.md` includes a “Decisions & Rationale” section.
- `AGENTS.md` states that `TheDriver.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` is the authoritative lockfile for app builds.

---

## Success Criteria

### Final Checklist
- All AGENTS/skills files exist at the specified paths
- All rules are grounded in repo references
- No tooling setup was added (docs-only scope respected)
