import FeatureCore
import SwiftUI

struct BootedDeviceView: View {
  let devices: [SimulatorDevice]
  let action: (SimulatorDevice) -> Void

  private let columns = Array(repeating: GridItem(.flexible(), spacing: DesignTokens.Spacing.x4), count: 3)
  
  var body: some View {
    VStack(spacing: .zero) {
      if devices.isEmpty {
        emptyState
      } else {
        header
          .padding(.bottom, DesignTokens.Spacing.x3)
        
        LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.x4) {
          ForEach(devices) { device in
            DeviceCell(device: device) {
              action(device)
            }
          }
        }
      }
    }
  }

  private var header: some View {
    HStack(spacing: DesignTokens.Spacing.x2) {
      Text("실행중인 기기")
        .font(DesignTokens.Typography.title2.font)
        .foregroundStyle(DesignTokens.Colors.text)
      
      Text("\(devices.count)")
        .font(DesignTokens.Typography.caption.font)
        .foregroundStyle(DesignTokens.Colors.accent)
        .padding(.vertical, DesignTokens.Spacing.x1)
        .padding(.horizontal, DesignTokens.Spacing.x2)
        .background {
          RoundedRectangle(cornerRadius: DesignTokens.Radius.control)
            .fill(DesignTokens.Colors.surfaceAccent)
        }
      
      Spacer()
    }
  }

  private var emptyState: some View {
    VStack(spacing: DesignTokens.Spacing.x2) {
      Image(systemName: "iphone.slash")
        .font(DesignTokens.Typography.title2.font)
        .foregroundStyle(DesignTokens.Colors.accent)
        .padding(DesignTokens.Spacing.x3)
        .background {
          Circle()
            .fill(DesignTokens.Colors.surfaceAccent)
        }
      
      Text("실행중인 기기가 없습니다")
        .font(DesignTokens.Typography.headline.font)
        .foregroundStyle(DesignTokens.Colors.text)
      
      Text("기기를 실행하면 여기에 표시됩니다")
        .font(DesignTokens.Typography.body.font)
        .foregroundStyle(DesignTokens.Colors.mutedText)
    }
    .multilineTextAlignment(.center)
    .frame(maxWidth: .infinity)
    .padding(DesignTokens.Spacing.x6)
    .background {
      RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
        .fill(DesignTokens.Colors.surface)
    }
    .overlay {
      RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
        .stroke(DesignTokens.Colors.border, lineWidth: 1)
    }
  }
}
