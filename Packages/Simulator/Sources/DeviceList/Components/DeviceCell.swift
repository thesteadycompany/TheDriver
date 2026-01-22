import FeatureCore
import SwiftUI

struct DeviceCell: View {
  let device: SimulatorDevice
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack(spacing: 4) {
        DeviceStateBadge(state: device.state)
        
        osView
      }
      
      titleView
    }
    .padding()
    .background {
      RoundedRectangle(cornerRadius: 16)
        .fill(.windowBackground)
    }
  }
  
  private var osView: some View {
    Text(device.os)
      .font(.caption)
      .foregroundStyle(.primary.secondary)
      .padding(.vertical, 4)
      .padding(.horizontal, 6)
      .background {
        RoundedRectangle(cornerRadius: 4)
          .foregroundStyle(.background.secondary)
      }
  }
  
  private var titleView: some View {
    Text(device.name)
      .font(.title)
      .foregroundStyle(.foreground)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}
