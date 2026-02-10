import FeatureCore
import SwiftUI

struct DeviceStateBadge: View {
  let state: DeviceState
  
  var body: some View {
    Text(state.title)
      .font(DesignTokens.Typography.caption.font)
      .foregroundStyle(state.isBooted ? DesignTokens.Colors.accent : DesignTokens.Colors.mutedText)
      .padding(.vertical, DesignTokens.Spacing.x1)
      .padding(.horizontal, DesignTokens.Spacing.x2)
      .background {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.control)
          .foregroundStyle(
            state.isBooted
              ? DesignTokens.Colors.accent.opacity(0.15)
              : DesignTokens.Colors.surfaceAccent
          )
      }
  }
}

fileprivate extension DeviceState {
  var title: String {
    switch self {
    case .booted: "실행 중"
    case .shutdown: "사용 가능"
    }
  }
}
