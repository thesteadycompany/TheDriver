import FeatureCore
import Foundation
import SwiftUI

@ViewAction(for: OnboardingFeature.self)
public struct OnboardingView: View {
  public let store: StoreOf<OnboardingFeature>

  private let logBottomAnchorID = "onboarding.install-log.bottom"

  public init(store: StoreOf<OnboardingFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: DesignTokens.Spacing.x6) {
      header
      statusSection
      actionSection
      installLogViewer
      Spacer(minLength: .zero)
    }
    .padding(DesignTokens.Spacing.x6)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(DesignTokens.Colors.background)
    .onAppear {
      send(.onAppear)
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: DesignTokens.Spacing.x2) {
      Text("시뮬레이터 환경 설정")
        .font(DesignTokens.Typography.title1.font)
        .foregroundStyle(DesignTokens.Colors.text)

      Text("Xcode 및 Simulator 설치 상태를 확인하고 필요한 항목을 설치하세요.")
        .font(DesignTokens.Typography.body.font)
        .foregroundStyle(DesignTokens.Colors.mutedText)
    }
  }

  private var statusSection: some View {
    VStack(alignment: .leading, spacing: DesignTokens.Spacing.x3) {
      statusRow(title: "Xcode", isReady: store.environmentStatus?.isXcodeInstalled)
      statusRow(title: "Simulator 앱", isReady: store.environmentStatus?.isSimulatorAppAvailable)
      statusRow(title: "simctl", isReady: store.environmentStatus?.isSimctlAvailable)

      if let status = store.environmentStatus {
        Text(status.detailMessage)
          .font(DesignTokens.Typography.caption.font)
          .foregroundStyle(status.isReady ? DesignTokens.Colors.success : DesignTokens.Colors.warning)
      }

      if let message = store.installErrorMessage {
        Text(message)
          .font(DesignTokens.Typography.caption.font)
          .foregroundStyle(DesignTokens.Colors.danger)
      }
    }
    .cardContainer()
  }

  private var actionSection: some View {
    HStack(spacing: DesignTokens.Spacing.x3) {
      Button(action: { send(.installTapped) }) {
        Text(store.isInstalling ? "설치 중..." : installButtonTitle)
          .font(DesignTokens.Typography.button.font)
      }
      .buttonStyle(.borderedProminent)
      .tint(DesignTokens.Colors.accent)
      .disabled(store.isInstalling || store.isChecking)

      Button(action: { send(.recheckTapped) }) {
        Text("다시 확인")
          .font(DesignTokens.Typography.button.font)
      }
      .buttonStyle(.bordered)
      .disabled(store.isInstalling)

      Button(action: { send(.clearLogsTapped) }) {
        Label("로그 지우기", systemImage: "trash")
          .font(DesignTokens.Typography.button.font)
      }
      .buttonStyle(.bordered)
      .disabled(store.installLogs.isEmpty)

      if store.isChecking {
        ProgressView()
          .controlSize(.small)
      }

      Spacer(minLength: .zero)
    }
  }

  private var installLogViewer: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(alignment: .leading, spacing: DesignTokens.Spacing.x1) {
          if store.installLogs.isEmpty {
            Text("설치 로그가 여기에 표시됩니다.")
              .font(DesignTokens.Typography.body.font)
              .foregroundStyle(DesignTokens.Colors.mutedText)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.vertical, DesignTokens.Spacing.x2)
          }

          ForEach(Array(store.installLogs.enumerated()), id: \.offset) { index, line in
            Text(line)
              .font(DesignTokens.Typography.caption.font.monospaced())
              .foregroundStyle(DesignTokens.Colors.text)
              .frame(maxWidth: .infinity, alignment: .leading)
              .textSelection(.enabled)
              .id(index)
          }

          Color.clear
            .frame(height: 1)
            .id(logBottomAnchorID)

          Color.clear
            .frame(height: 0)
            .id(logScrollObserverID)
            .onAppear {
              scrollToBottom(proxy, animated: store.installLogs.isEmpty == false)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .onAppear {
        scrollToBottom(proxy, animated: false)
      }
    }
    .frame(minHeight: 240, maxHeight: 320)
    .cardContainer()
  }

  private struct LogScrollObserverID: Hashable {
    let count: Int
    let first: String?
    let last: String?
  }

  private var logScrollObserverID: LogScrollObserverID {
    LogScrollObserverID(
      count: store.installLogs.count,
      first: store.installLogs.first,
      last: store.installLogs.last
    )
  }

  private var installButtonTitle: String {
    if store.environmentStatus?.isXcodeInstalled == false {
      return "Xcode 설치"
    }
    return "Simulator 환경 설치"
  }

  private func statusRow(title: String, isReady: Bool?) -> some View {
    HStack(spacing: DesignTokens.Spacing.x2) {
      Circle()
        .fill(statusColor(isReady))
        .frame(width: DesignTokens.Spacing.x2, height: DesignTokens.Spacing.x2)

      Text(title)
        .font(DesignTokens.Typography.body.font)
        .foregroundStyle(DesignTokens.Colors.text)

      Spacer(minLength: .zero)

      Text(statusLabel(isReady))
        .font(DesignTokens.Typography.caption.font)
        .foregroundStyle(DesignTokens.Colors.mutedText)
    }
  }

  private func statusLabel(_ isReady: Bool?) -> String {
    guard let isReady else { return "확인 중" }
    return isReady ? "완료" : "필요"
  }

  private func statusColor(_ isReady: Bool?) -> Color {
    guard let isReady else { return DesignTokens.Colors.border }
    return isReady ? DesignTokens.Colors.success : DesignTokens.Colors.warning
  }

  private func scrollToBottom(_ proxy: ScrollViewProxy, animated: Bool) {
    DispatchQueue.main.async {
      if animated {
        withAnimation(.easeOut(duration: 0.2)) {
          proxy.scrollTo(logBottomAnchorID, anchor: .bottom)
        }
      } else {
        proxy.scrollTo(logBottomAnchorID, anchor: .bottom)
      }
    }
  }
}
