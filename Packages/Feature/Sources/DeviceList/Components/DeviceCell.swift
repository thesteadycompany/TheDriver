import FeatureCore
import SwiftUI

struct DeviceCell: View {
  let device: SimulatorDevice
  let action: () -> Void
  
  private var buttonTitle: String {
    if !device.isAvailable {
      return "사용 불가능"
    }
    switch device.state {
    case .booted: return "종료하기"
    case .shutdown: return "실행하기"
    }
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: .zero) {
      HStack(spacing: 4) {
        DeviceStateBadge(state: device.state)
        
        osView
      }
      
      titleView
        .padding(.top, DesignTokens.Spacing.x2)
      
      actionButton
        .padding(.top, DesignTokens.Spacing.x4)
    }
    .cardContainer()
  }
  
  private var osView: some View {
    Text(device.os)
      .font(DesignTokens.Typography.caption.font)
      .foregroundStyle(DesignTokens.Colors.mutedText)
      .padding(.vertical, DesignTokens.Spacing.x1)
      .padding(.horizontal, DesignTokens.Spacing.x2)
      .background {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.control)
          .foregroundStyle(DesignTokens.Colors.surfaceAccent)
      }
  }
  
  private var titleView: some View {
    Text(device.name)
      .font(DesignTokens.Typography.headline.font)
      .foregroundStyle(DesignTokens.Colors.text)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
  
  private var actionButton: some View {
    Button(action: action) {
      Text(buttonTitle)
        .font(DesignTokens.Typography.button.font)
    }
    .buttonStyle(.borderedProminent)
    .tint(DesignTokens.Colors.accent)
    .disabled(!device.isAvailable)
  }
}
