import FeatureCore
import SwiftUI

struct DeviceGroupView: View {
  let group: DeviceGroup
  let action: (SimulatorDevice) -> Void
  
  private let columns = Array(repeating: GridItem(.flexible()), count: 3)
  
  var body: some View {
    VStack(spacing: .zero) {
      Text(group.os)
        .font(DesignTokens.Typography.title2.font)
        .foregroundStyle(DesignTokens.Colors.mutedText)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, DesignTokens.Spacing.x3)
      
      LazyVGrid(columns: columns) {
        ForEach(group.devices) { device in
          DeviceCell(device: device) {
            action(device)
          }
        }
      }
    }
  }
}
