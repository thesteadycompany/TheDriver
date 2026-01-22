import FeatureCore
import SwiftUI

struct DeviceStateBadge: View {
  let state: DeviceState
  
  var body: some View {
    Text(state.title)
      .font(.caption)
      .foregroundStyle(state.textColor)
      .padding(4)
      .background {
        if state.isBooted {
          RoundedRectangle(cornerRadius: 4)
            .fill(.tint)
        }
      }
  }
}

fileprivate extension DeviceState {
  var title: String {
    switch self {
    case .booted: "실행중"
    case .shutdown: "꺼져있음"
    }
  }
  
  var textColor: HierarchicalShapeStyle {
    switch self {
    case .booted: .primary
    case .shutdown: .secondary
    }
  }
}
