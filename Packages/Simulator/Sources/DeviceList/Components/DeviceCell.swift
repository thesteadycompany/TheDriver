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
        .padding(.top, 8)
      
      actionButton
        .padding(.top, 16)
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
  
  private var actionButton: some View {
    Button(action: action) {
      Text(buttonTitle)
    }
    .buttonStyle(.borderedProminent)
    .disabled(!device.isAvailable)
  }
}
