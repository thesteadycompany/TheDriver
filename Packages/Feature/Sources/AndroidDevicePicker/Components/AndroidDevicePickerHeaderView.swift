import FeatureCore
import SwiftUI

struct AndroidDevicePickerHeaderView: View {
  let appBundle: AppBundle
  let isEnabled: Bool
  let action: () -> Void

  var body: some View {
    HStack {
      appIcon

      titleView

      Spacer()

      actionButton
    }
  }

  private var appIcon: some View {
    Image(
      nsImage: NSWorkspace.shared.icon(forFile: appBundle.url.path)
    )
    .resizable()
    .frame(
      width: DesignTokens.Spacing.x16,
      height: DesignTokens.Spacing.x16
    )
  }

  private var titleView: some View {
    Text(appBundle.name)
      .font(DesignTokens.Typography.headline.font)
      .foregroundStyle(DesignTokens.Colors.text)
  }

  private var actionButton: some View {
    Button(action: action) {
      Text("저장하기")
        .font(DesignTokens.Typography.button.font)
    }
    .buttonStyle(.borderedProminent)
    .tint(DesignTokens.Colors.accent)
    .disabled(!isEnabled)
  }
}
