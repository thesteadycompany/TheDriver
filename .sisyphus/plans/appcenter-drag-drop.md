# AppCenter Upload Drag & Drop

## TL;DR

> **Quick Summary**: `AppCenterUploadButton`를 Finder 드래그앤드랍 drop target로 만들고, drag-over 시 hover(타겟팅) UI를 보여주며, drop 시 기존 `fileImporter`와 동일한 경로로 `.app` URL을 처리해 모델을 갱신한다.
>
> **Deliverables**:
> - `AppCenterUploadButton` drag-over(highlight) + drop 핸들러
> - drop 시 `AppCenterFeature`의 기존 파일 선택 처리(`fileSelected`)로 연결
> - invalid drop(non-.app) 시 error 토스트 대신 warning 토스트
> - 자동 검증을 위한 XCTest 기반 테스트 타겟/테스트(최소 unit + 가능하면 macOS UI 테스트)
>
> **Estimated Effort**: Medium
> **Parallel Execution**: YES - 2 waves
> **Critical Path**: (Drop UI wiring) → (Reducer warning handling) → (Tests)

---

## Context

### Original Request
- `Packages/Feature/Sources/AppCenter/AppCenterView.swift` 화면에서 `Packages/Feature/Sources/AppCenter/Components/AppCenterUploadButton.swift` 영역에 파일을 Drag 하면 Hover가 되고, Drop 하면 값이 Set 되는 기능 추가.

### Interview Summary
- Drop behavior: 드랍된 앱으로 리스트를 **교체** (현재 `setModels([single])`와 정합).
- Invalid drop UX: **토스트 경고** (예: "지원하지 않는 파일입니다. (.app)").
- Verification: **Xcode 테스트 타겟/테스트 추가**(사용자 의사)로 자동 검증 포함.

### Codebase Notes (observed)
- AppCenter 화면은 현재 `.fileImporter(allowedContentTypes: [.applicationBundle])`로 파일 선택 후 `send(.fileSelected(...))` 경로로 reducer가 처리.
- `AppBundleClient`는 `url.pathExtension == "app"`만 지원하고 아니면 `AppBundleError.notSupportedFormat`를 throw.
- `Effect.runWithToast`는 throw를 catch하면 **항상** `toastClient.showError(error)`를 호출.
- SwiftPM Package.swift들에는 `testTarget`이 없고, Xcode 프로젝트도 빠른 스캔상 테스트 타겟이 보이지 않아(정확 검증은 executor 단계에서 재확인) 테스트 인프라를 이번 작업에서 마련하는 쪽으로 계획.

### Metis Review (key guardrails)
- XCUITest로 Finder→앱 드랍을 완전 자동화하는 것은 환경/권한/플레이키 이슈가 있을 수 있음.
- 대응: reducer-level XCTest(=TCA TestStore)로 drop 처리 로직을 안정적으로 커버하고, UI test는 **가능한 범위 내에서**(동일 앱 내부 드래그 또는 Finder 자동화 가능 시) 확장.

---

## Work Objectives

### Core Objective
- AppCenter 업로드 UI가 드래그앤드랍을 지원하여 사용자가 `.app` 번들을 드랍하면 기존 파일 선택과 동일하게 모델이 갱신되고, drag-over 동안 시각적 hover 상태가 표시되도록 한다.

### Concrete Deliverables
- Drop target + hover UI: `Packages/Feature/Sources/AppCenter/Components/AppCenterUploadButton.swift`
- Drop wiring: `Packages/Feature/Sources/AppCenter/AppCenterView.swift`
- Warning toast handling for invalid `.app`: `Packages/Feature/Sources/AppCenter/AppCetnerFeature.swift`
- Automated tests infrastructure + tests: (SwiftPM testTarget 또는 Xcode test targets) + 테스트 파일

### Must Have
- Drag-over 상태에서 upload 영역이 명확히 하이라이트 된다.
- Drop 시 첫 번째 유효 `.app` URL이 선택되어 기존과 동일하게 `models`가 교체된다.
- non-.app drop 시 error 토스트가 아니라 warning 토스트가 뜬다.

### Must NOT Have (Guardrails)
- multi-upload(여러 앱 누적), 저장/영속화, 앱 포맷 확대(.ipa/.zip)는 이번 작업에서 하지 않는다.
- `Effect.runWithToast` 공용 동작 변경(전역 toast 정책 변경)은 하지 않는다.
- 파일명/타겟명 정리 차원의 리네이밍(예: `AppCetnerFeature.swift` 오타 수정) 같은 범위 확장은 하지 않는다.

---

## Verification Strategy (MANDATORY)

> **UNIVERSAL RULE: ZERO HUMAN INTERVENTION**
>
> 모든 acceptance criteria는 agent가 커맨드 실행 또는 자동화로 검증 가능해야 한다.

### Test Decision
- **Infrastructure exists**: NO (SwiftPM/Xcode 모두 테스트 타겟이 명확히 존재하지 않음)
- **Automated tests**: YES (Tests-after)
- **Framework**: XCTest (TCA TestStore + 가능하면 macOS UI Tests)

### Agent-Executed QA Scenarios (overall)
- Tool: Bash (`xcodebuild`) + (필요시) Xcode UI Test runner
- 핵심 검증은 `xcodebuild test`가 PASS하는 것으로 둔다.

---

## Execution Strategy

### Parallel Execution Waves

Wave 1 (Start Immediately):
├── Task 1: UploadButton drop target + hover UI
└── Task 2: Reducer invalid-format warning 처리

Wave 2 (After Wave 1):
└── Task 3: XCTest 인프라 + 테스트 작성 + xcodebuild test 통과

Critical Path: Task 1 → Task 2 → Task 3

---

## TODOs

- [x] 1. `AppCenterUploadButton`에 drag-over hover + drop handler 추가

  **What to do**:
  - `Packages/Feature/Sources/AppCenter/Components/AppCenterUploadButton.swift`에 drop target 기능을 추가한다.
  - 권장 API shape:
    - `struct AppCenterUploadButton: View { let action: () -> Void; let onDropAppURL: (URL) -> Void }`
    - (호출측에서 drop을 쓰지 않는 곳이 생길 수 있으면 `onDropAppURL: ((URL) -> Void)?`로 optional 처리)
  - 구현 옵션(권장): `dropDestination(for: URL.self, ...)`를 outer container(HStack 또는 전체 카드)에 적용하고, 전달받은 `[URL]`에서 첫 번째 `.app`만 골라 `onDropAppURL(url)`로 전달한다.
  - hover 시각화: drop target이 타겟팅될 때 `RoundedRectangle` stroke를 `DesignTokens.Colors.accent`로 변경하고 lineWidth를 2로 올리며, background에 `DesignTokens.Colors.surfaceAccent`를 약간(예: opacity 0.15~0.25) 깔아준다.
  - 접근성: UI 테스트 안정성을 위해 drop zone에 `accessibilityIdentifier`를 부여한다(예: `appcenter.upload.dropzone`). 또한 hover 상태를 `accessibilityValue`로 노출한다(예: `"targeted"` / `"idle"`).
  - 기존 탭 업로드(plus 버튼) 동작은 유지한다.

  **Must NOT do**:
  - drop 시 여러 파일을 누적 처리하지 않는다(첫 번째 유효 `.app`만 사용).
  - 새로운 디자인 토큰을 만들지 않는다(기존 `DesignTokens` 조합으로 해결).

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: SwiftUI modifier/drag-drop API + 스타일링 + 접근성 ID까지 포함.
  - **Skills**: (없음)
    - 이 repo 전용 스킬을 executor가 로드할 수 있다면 `tca-the-driver`, `swift-style-the-driver`, `xcode-workflow-the-driver`를 우선.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Task 2)
  - **Blocks**: Task 3
  - **Blocked By**: None

  **References**:
  - `Packages/Feature/Sources/AppCenter/Components/AppCenterUploadButton.swift` - drop target을 추가할 실제 UI 컴포넌트.
  - `Packages/Feature/Sources/AppCenter/AppCenterView.swift` - 이 컴포넌트가 사용되는 위치; drop callback을 store action으로 연결.
  - `Packages/Platform/Sources/DesignSystem/DesignTokens.swift` - hover 시 stroke/background에 사용할 색/spacing/radius 토큰.

  **Acceptance Criteria**:
  - [ ] `AppCenterUploadButton`가 `accessibilityIdentifier("appcenter.upload.dropzone")`를 가진다.
  - [ ] drag-over 타겟팅 상태를 표현하는 UI 분기(정상/targeted)가 코드상 존재한다(overlay stroke 색/굵기, background fill).
  - [ ] drop handler가 `[URL]`를 받아 첫 번째 `.app` URL을 선택하여 상위로 전달한다.

  **Agent-Executed QA Scenarios**:

  ```
  Scenario: Build confirms drop modifiers compile
    Tool: Bash (xcodebuild)
    Preconditions: Xcode 설치, 프로젝트 정상 상태
    Steps:
      1. Run: xcodebuild -project TheDriver.xcodeproj -scheme TheDriver -configuration Debug build
      2. Assert: exit code 0
    Expected Result: 컴파일/빌드 성공
    Evidence: xcodebuild stdout/stderr
  ```

- [x] 2. Drop/파일 선택 실패 시 `notSupportedFormat`는 warning 토스트로 처리

  **What to do**:
  - `Packages/Feature/Sources/AppCenter/AppCetnerFeature.swift`의 `.fileSelected(.success(url))` 처리에서 `AppBundleClient.appBundle(url:)` 호출을 `do/catch`로 감싸서 `AppBundleError.notSupportedFormat`은 throw 하지 않고 `ToastClient.showWarning("지원하지 않는 파일입니다. (.app)")` 후 early-return 한다.
  - 그 외 에러는 기존대로 error 토스트가 뜨도록 rethrow해서 `runWithToast` catch 경로를 타게 한다.
  - 성공 시에는 기존대로 `setModels([.init(appBundle: appBundle)])`로 모델 교체.

  **Must NOT do**:
  - `Effect.runWithToast` 공용 구현(`Packages/Platform/Sources/FeatureCore/Extensions/Effect+.swift`)을 변경하지 않는다.

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: reducer 로직의 작은 분기 추가.
  - **Skills**: (없음)

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Task 1)
  - **Blocks**: Task 3
  - **Blocked By**: None

  **References**:
  - `Packages/Feature/Sources/AppCenter/AppCetnerFeature.swift` - `.fileSelected` 처리 로직.
  - `Packages/Clients/Sources/AppBundleClient/Live.swift` - `.app` 여부 판단 + `AppBundleError.notSupportedFormat` throw.
  - `Packages/Platform/Sources/FeatureCore/Extensions/Effect+.swift` - throw 시 error toast가 자동 노출되는 이유.

  **Acceptance Criteria**:
  - [ ] `.fileSelected(.success(url))`에서 `.app`이 아닌 URL이면 error 토스트가 아닌 warning 토스트를 호출하고, 상태 변경(`models`)은 발생하지 않는다.
  - [ ] 다른 에러는 기존대로 error 토스트로 노출된다.

  **Agent-Executed QA Scenarios**:

  ```
  Scenario: Reducer handles non-.app URL with warning (unit-level)
    Tool: Bash (xcodebuild test) or SwiftPM swift test
    Preconditions: Test infra added in Task 3
    Steps:
      1. Run tests (see Task 3 commands)
      2. Assert: test for non-.app case passes
    Expected Result: notSupportedFormat is warning-only
    Evidence: test output
  ```

- [x] 3. XCTest 인프라 추가 + 자동 검증(최소 unit + 가능하면 macOS UI)

  **What to do**:
  - 테스트 인프라를 추가한다(둘 중 하나로 통일):
    - A) SwiftPM: `Packages/Feature/Package.swift`에 `.testTarget(name: "AppCenterTests", dependencies: ["AppCenter"])` 추가 + `Packages/Feature/Tests/AppCenterTests/...`에 XCTest 작성.
    - B) Xcode: `TheDriver.xcodeproj`에 unit test target + (가능하면) UI test target 추가.
  - 우선순위: A(단순/안정)로 reducer 로직을 확실히 커버 + B는 환경이 허용하면(권한/플레이키 감수) Finder에서 `.app`을 드랍하는 UI 자동화를 시도.
  - TCA reducer 테스트:
    - `.uploadTapped` → `isFileImporterPresented == true`
    - valid `.app` URL → `models`가 1개로 교체
    - invalid URL (`/tmp/a.txt`) → warning 토스트 호출(ToastClient test double로 `Toast.warning("지원하지 않는 파일입니다. (.app)")` 같은 값을 기록/검증)
  - UI 테스트(가능할 때만):
    - Drop zone element 존재/identifier 확인
    - Finder(`/Applications`)에서 하나의 `.app`(예: `Calculator.app`)를 드래그하여 drop zone에 드랍
    - 드랍 이후 `AppBundleCell`에 accessibilityIdentifier를 부여해(예: `appcenter.appbundlecell.<bundleID>`) 존재를 assert
      - 이 변경은 `Packages/Feature/Sources/AppCenter/Components/AppBundleCell.swift`에 들어간다.

  **Must NOT do**:
  - 테스트를 위해 프로덕션 UI에 눈에 띄는 테스트 전용 버튼/화면을 추가하지 않는다(필요 시 `#if DEBUG` + 테스트 런 모드에서만 노출).

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: SPM/Xcode 테스트 타겟 추가는 파일/설정 범위가 넓고 실수 가능성이 큼.
  - **Skills**: `xcode-workflow-the-driver`
    - `xcode-workflow-the-driver`: xcodebuild/test, scheme/target 관리, repo hygiene.

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2 (after Tasks 1-2)
  - **Blocks**: None (final)
  - **Blocked By**: Tasks 1-2

  **References**:
  - `Packages/Feature/Package.swift` - SwiftPM 테스트 타겟 추가 시 수정 위치.
  - `Packages/Feature/Sources/AppCenter/AppCetnerFeature.swift` - TestStore 대상 reducer.
  - `Packages/Feature/Sources/AppCenter/Components/AppBundleCell.swift` - UI test에서 drop 성공을 안정적으로 검증하기 위한 접근성 identifier 부여 지점.
  - `Packages/Platform/Sources/FeatureCore/FeatureCore.swift` - Feature layer import 패턴(테스트에서도 가능하면 동일하게 유지).
  - `TheDriver.xcodeproj/project.pbxproj` - Xcode 테스트 타겟 추가가 필요할 경우.

  **Acceptance Criteria**:
  - [ ] 최소 1개 이상의 XCTest가 추가되어 drop 처리 로직을 자동 검증한다.
  - [ ] `xcodebuild -project TheDriver.xcodeproj -scheme TheDriver -configuration Debug build` → exit 0
  - [ ] (SwiftPM 선택 시) `swift test --package-path Packages/Feature` → PASS
  - [ ] (Xcode test target 선택 시) `xcodebuild -project TheDriver.xcodeproj -scheme TheDriver test` → PASS

  **Agent-Executed QA Scenarios**:

  ```
  Scenario: Unit tests cover drop selection + warning toast
    Tool: Bash (swift test or xcodebuild test)
    Preconditions: Test targets added
    Steps:
      1. Run: swift test --package-path Packages/Feature
      2. Assert: exit code 0
      3. Assert: AppCenter drop-related tests executed (e.g., AppCenterTests)
    Expected Result: reducer behavior validated automatically
    Evidence: test runner output
  ```

---

## Success Criteria

### Verification Commands

```bash
# Build
xcodebuild -project TheDriver.xcodeproj -scheme TheDriver -configuration Debug build

# Tests (one or both depending on chosen infra)
swift test --package-path Packages/Feature
xcodebuild -project TheDriver.xcodeproj -scheme TheDriver test
```

### Final Checklist
- [x] Upload 영역에 drag-over hover UI가 코드상 구현되어 있음(DesignTokens 기반)
- [x] Drop 시 `.app` URL이 기존 처리 경로로 들어가 models가 교체됨
- [x] non-.app drop 시 warning 토스트(에러 토스트 아님)
- [x] 빌드 + 테스트 자동 검증 PASS
