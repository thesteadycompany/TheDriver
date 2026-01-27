import FeatureCore
import SwiftUI

struct DevicePickerCell: View {
  let device: SimulatorDevice
  let isCurrent: Bool
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: DesignTokens.Spacing.x2) {
        Text(device.os)
          .font(DesignTokens.Typography.caption.font)
          .foregroundStyle(DesignTokens.Colors.mutedText)
        
        Text(device.name)
          .font(DesignTokens.Typography.body.font)
          .foregroundStyle(DesignTokens.Colors.text)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(DesignTokens.Spacing.x4)
      .background {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
          .fill(
            isCurrent ? DesignTokens.Colors.surfaceAccent : DesignTokens.Colors.surface
          )
      }
      .overlay {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
          .stroke(
            isCurrent ? DesignTokens.Colors.accent : DesignTokens.Colors.border,
            lineWidth: 1
          )
      }
    }
    .buttonStyle(.plain)
  }
}
