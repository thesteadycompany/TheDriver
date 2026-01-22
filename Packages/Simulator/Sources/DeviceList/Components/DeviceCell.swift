import FeatureCore
import SwiftUI

struct DeviceCell: View {
  let device: SimulatorDevice
  
  var body: some View {
    VStack(alignment: .leading) {
      DeviceStateBadge(state: device.state)
      
      HStack {
        iconView
        
        titleView
      }
    }
  }
  
  private var iconView: some View {
    Image(systemName: device.systemName)
      .renderingMode(.template)
      .font(.title)
      .foregroundStyle(.foreground)
      .padding()
      .background {
        RoundedRectangle(cornerRadius: 8)
          .fill(.gray.secondary)
      }
  }
  
  private var titleView: some View {
    Text(device.name)
      .font(.title)
      .foregroundStyle(.foreground)
  }
}

fileprivate extension SimulatorDevice {
  var systemName: String {
    if isIPhone {
      "iphone"
    } else if isIPad {
      "ipad"
    } else {
      "apple.logo"
    }
  }
}
