import FeatureCore
import Foundation
import SwiftUI

@ViewAction(for: DeviceLoggingFeature.self)
public struct DeviceLoggingView: View {
  public let store: StoreOf<DeviceLoggingFeature>

  private let bottomAnchorID = "device-logging.bottom"

  public init(store: StoreOf<DeviceLoggingFeature>) {
    self.store = store
  }
  
  public var body: some View {
    VStack(spacing: .zero) {
      if store.runningApp != nil {
        header
          .padding(.horizontal, DesignTokens.Spacing.x6)
          .padding(.top, DesignTokens.Spacing.x6)
          .padding(.bottom, DesignTokens.Spacing.x4)

        logViewer
          .padding(.horizontal, DesignTokens.Spacing.x6)
          .padding(.bottom, DesignTokens.Spacing.x6)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      } else {
        emptyState
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding(.horizontal, DesignTokens.Spacing.x6)
          .padding(.vertical, DesignTokens.Spacing.x8)
      }
    }
    .onAppear {
      send(.onAppear)
    }
    .onDisappear {
      send(.onDisappear)
    }
    .background(DesignTokens.Colors.background)
  }

  private var header: some View {
    Group {
      if let runningApp = store.runningApp {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.x4) {
          HStack(alignment: .top, spacing: DesignTokens.Spacing.x4) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.x1) {
              Text(runningApp.displayName)
                .font(DesignTokens.Typography.title2.font)
                .foregroundStyle(DesignTokens.Colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)

              Text("기기 ID: \(runningApp.deviceId)")
                .font(DesignTokens.Typography.caption.font)
                .foregroundStyle(DesignTokens.Colors.mutedText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
            }

            streamingStatus
          }

          HStack(spacing: DesignTokens.Spacing.x3) {
            Button {
              send(.cancelTapped)
            } label: {
              Label("취소", systemImage: "xmark")
                .font(DesignTokens.Typography.button.font)
            }
            .buttonStyle(.bordered)
            .tint(DesignTokens.Colors.danger)
            .disabled(store.isPaused)
            .opacity(store.isPaused ? 0.5 : 1)

            Button {
              send(.clearTapped)
            } label: {
              Label("지우기", systemImage: "trash")
                .font(DesignTokens.Typography.button.font)
            }
            .buttonStyle(.bordered)
            .disabled(store.logLines.isEmpty)

            Spacer(minLength: .zero)
          }

          TextField(
            "로그 검색",
            text: Binding(
              get: { store.searchInput },
              set: { send(.searchQueryChanged($0)) }
            )
          )
          .textFieldStyle(.roundedBorder)

          HStack(spacing: DesignTokens.Spacing.x2) {
            Spacer(minLength: .zero)

            Button {
              send(.searchSubmitted)
            } label: {
              Image(systemName: "chevron.up")
                .font(DesignTokens.Typography.button.font)
            }
            .buttonStyle(.bordered)
            .disabled(store.matchedLineIndices.isEmpty)
            .accessibilityLabel("이전 검색 결과")

            Button {
              send(.searchPreviousTapped)
            } label: {
              Image(systemName: "chevron.down")
                .font(DesignTokens.Typography.button.font)
            }
            .buttonStyle(.bordered)
            .disabled(store.matchedLineIndices.isEmpty)
            .accessibilityLabel("다음 검색 결과")
          }

          if store.searchQuery.isEmpty == false {
            Text(searchMatchStatusText)
              .font(DesignTokens.Typography.caption.font)
              .foregroundStyle(DesignTokens.Colors.mutedText)
          }
        }
        .cardContainer()
      }
    }
  }

  private var streamingStatus: some View {
    HStack(spacing: DesignTokens.Spacing.x2) {
      Circle()
        .fill(statusModel.color)
        .frame(width: DesignTokens.Spacing.x2, height: DesignTokens.Spacing.x2)

      Text(statusModel.title)
        .font(DesignTokens.Typography.caption.font)
        .foregroundStyle(DesignTokens.Colors.text)
    }
    .padding(.vertical, DesignTokens.Spacing.x1)
    .padding(.horizontal, DesignTokens.Spacing.x2)
    .background {
      RoundedRectangle(cornerRadius: DesignTokens.Radius.pill)
        .fill(DesignTokens.Colors.surfaceAccent)
    }
    .overlay {
      RoundedRectangle(cornerRadius: DesignTokens.Radius.pill)
        .stroke(DesignTokens.Colors.border, lineWidth: 1)
    }
    .transaction { transaction in
      transaction.animation = .easeInOut(duration: 0.2)
    }
  }

  private var logViewer: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(alignment: .leading, spacing: DesignTokens.Spacing.x1) {
          if store.logLines.isEmpty {
            Text(store.isPaused ? "로그 일시 정지됨." : "로그 대기 중...")
              .font(DesignTokens.Typography.body.font)
              .foregroundStyle(DesignTokens.Colors.mutedText)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.vertical, DesignTokens.Spacing.x2)
          }

          ForEach(Array(store.logLines.enumerated()), id: \.offset) { index, line in
            Text(
              highlightedLogLine(
                line,
                query: store.searchQuery,
                isCurrentMatch: index == store.currentMatchedLineIndex
              )
            )
              .font(DesignTokens.Typography.caption.font.monospaced())
              .foregroundStyle(DesignTokens.Colors.text)
              .frame(maxWidth: .infinity, alignment: .leading)
              .textSelection(.enabled)
              .id(index)
          }

          Color.clear
            .frame(height: 1)
            .id(bottomAnchorID)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .onAppear {
        scrollForCurrentState(proxy, animated: false)
      }
      .onChange(of: store.currentMatchedLineIndex) { _, _ in
        scrollForCurrentState(proxy, animated: true)
      }
      .onChange(of: store.searchNavigationTick) { _, _ in
        scrollForCurrentState(proxy, animated: true)
      }
      .onChange(of: store.searchQuery) { _, _ in
        scrollForCurrentState(proxy, animated: true)
      }
      .onChange(of: store.logLines.count) { _, _ in
        scrollForCurrentState(proxy, animated: true)
      }
    }
    .cardContainer()
  }

  private func highlightedLogLine(
    _ line: String,
    query: String,
    isCurrentMatch: Bool
  ) -> AttributedString {
    var attributed = AttributedString(line)
    guard query.isEmpty == false else { return attributed }

    var searchRange = line.startIndex..<line.endIndex
    while
      let matchedRange = line.range(
        of: query,
        options: [.caseInsensitive, .diacriticInsensitive],
        range: searchRange,
        locale: .current
      )
    {
      if let attributedRange = Range(matchedRange, in: attributed) {
        attributed[attributedRange].backgroundColor =
          isCurrentMatch
          ? DesignTokens.Colors.warning.opacity(0.45)
          : DesignTokens.Colors.info.opacity(0.2)
      }

      searchRange = matchedRange.upperBound..<line.endIndex
      if searchRange.isEmpty {
        break
      }
    }

    return attributed
  }

  private var searchMatchStatusText: String {
    let matchedCount = store.matchedLineIndices.count
    guard matchedCount > 0 else { return "일치 0개" }

    if
      let currentMatchPointer = store.currentMatchPointer,
      store.matchedLineIndices.indices.contains(currentMatchPointer)
    {
      let bottomUpPosition = matchedCount - currentMatchPointer
      return "현재 \(bottomUpPosition)/\(matchedCount) · 일치 \(matchedCount)개"
    }

    return "일치 \(matchedCount)개"
  }

  private var emptyState: some View {
    VStack(spacing: DesignTokens.Spacing.x4) {
      Image(systemName: "waveform")
        .font(DesignTokens.Typography.display.font)
        .foregroundStyle(DesignTokens.Colors.mutedText)

      Text("실행 중인 앱이 없습니다")
        .font(DesignTokens.Typography.title2.font)
        .foregroundStyle(DesignTokens.Colors.text)

      Text("AppCenter에서 앱을 실행하면 여기에 고정되고 로그가 스트리밍됩니다.")
        .font(DesignTokens.Typography.body.font)
        .foregroundStyle(DesignTokens.Colors.mutedText)
        .multilineTextAlignment(.center)
        .frame(maxWidth: 420)
    }
  }

  private struct StatusModel: Equatable {
    let title: String
    let color: Color
  }

  private var statusModel: StatusModel {
    if store.isPaused {
      return StatusModel(title: "일시 정지", color: DesignTokens.Colors.warning)
    }
    if store.isLogging {
      return StatusModel(title: "스트리밍 중", color: DesignTokens.Colors.success)
    }
    return StatusModel(title: "중지됨", color: DesignTokens.Colors.border)
  }

  private func scrollForCurrentState(_ proxy: ScrollViewProxy, animated: Bool) {
    if store.searchQuery.isEmpty == false, let currentMatchedLineIndex = store.currentMatchedLineIndex {
      scrollToMatch(proxy, index: currentMatchedLineIndex, animated: animated)
      return
    }

    if store.searchQuery.isEmpty {
      scrollToBottom(proxy, animated: animated)
    }
  }

  private func scrollToMatch(_ proxy: ScrollViewProxy, index: Int, animated: Bool) {
    DispatchQueue.main.async {
      if animated {
        withAnimation(.easeOut(duration: 0.2)) {
          proxy.scrollTo(index, anchor: .center)
        }
      } else {
        proxy.scrollTo(index, anchor: .center)
      }
    }
  }

  private func scrollToBottom(_ proxy: ScrollViewProxy, animated: Bool) {
    DispatchQueue.main.async {
      if animated {
        withAnimation(.easeOut(duration: 0.2)) {
          proxy.scrollTo(bottomAnchorID, anchor: .bottom)
        }
      } else {
        proxy.scrollTo(bottomAnchorID, anchor: .bottom)
      }
    }
  }
}
