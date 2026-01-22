import FeatureCore
import SwiftUI

struct DeviceStateBadge: View {
  let state: DeviceState
  
  var body: some View {
    Text(state.title)
      .font(.caption)
      .foregroundStyle(state.textColor)
      .padding(.vertical, 4)
      .padding(.horizontal, 6)
      .background {
        RoundedRectangle(cornerRadius: 4)
          .foregroundStyle(state.isBooted ? .blue.opacity(0.2) : .gray.opacity(0.2))
      }
  }
}

fileprivate extension DeviceState {
  var title: String {
    switch self {
    case .booted: "부팅 됨"
    case .shutdown: "사용 가능"
    }
  }
  
  var textColor: Color {
    switch self {
    case .booted: .blue
    case .shutdown: .gray.opacity(0.6)
    }
  }
}
