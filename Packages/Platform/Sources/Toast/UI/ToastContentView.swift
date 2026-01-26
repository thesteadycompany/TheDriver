import DesignSystem
import SwiftUI

struct ToastContentView: View {
  let toast: Toast
  
  var body: some View {
    HStack(spacing: .zero) {
      icon
      message
    }
    .padding(.vertical, DesignTokens.Spacing.x4)
    .padding(.horizontal, DesignTokens.Spacing.x6)
    .background {
      Capsule()
        .foregroundStyle(DesignTokens.Colors.surface)
    }
  }
  
  private var message: some View {
    Text(toast.message)
      .font(DesignTokens.Typography.title2.font)
      .foregroundStyle(DesignTokens.Colors.text)
  }
  
  @ViewBuilder
  private var icon: some View {
    switch toast.style {
    case .plain:
      EmptyView()
      
    case .success:
      Image(systemName: "checkmark.circle.fill")
        .renderingMode(.template)
        .resizable()
        .frame(width: DesignTokens.Spacing.x6, height: DesignTokens.Spacing.x6)
        .foregroundStyle(DesignTokens.Colors.success)
        .padding(.trailing, DesignTokens.Spacing.x4)
      
    case .failure:
      Image(systemName: "x.circle.fill")
        .renderingMode(.template)
        .resizable()
        .frame(width: DesignTokens.Spacing.x6, height: DesignTokens.Spacing.x6)
        .foregroundStyle(DesignTokens.Colors.danger)
        .padding(.trailing, DesignTokens.Spacing.x4)
      
    case .warning:
      Image(systemName: "exclamationmark.triangle.fill")
        .renderingMode(.template)
        .resizable()
        .frame(width: DesignTokens.Spacing.x6, height: DesignTokens.Spacing.x6)
        .foregroundStyle(DesignTokens.Colors.warning)
        .padding(.trailing, DesignTokens.Spacing.x4)
    }
  }
}
