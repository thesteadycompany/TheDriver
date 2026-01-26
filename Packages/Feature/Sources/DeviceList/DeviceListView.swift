import FeatureCore
import SwiftUI

@ViewAction(for: DeviceListFeature.self)
public struct DeviceListView: View {
  public let store: StoreOf<DeviceListFeature>
  
  public init(store: StoreOf<DeviceListFeature>) {
    self.store = store
  }
  
  public var body: some View {
    ScrollView {
      VStack(spacing: DesignTokens.Spacing.x8) {
        BootedDeviceView(devices: store.bootedDevices) {
          send(.deviceTapped($0))
        }
        
        ForEach(store.shutdownGroups) { group in
          DeviceGroupView(group: group) {
            send(.deviceTapped($0))
          }
        }
      }
      .padding(.horizontal, DesignTokens.Spacing.x6)
      .padding(.vertical, DesignTokens.Spacing.x8)
    }
    .onAppear {
      send(.onAppear)
    }
    .background(DesignTokens.Colors.background)
  }
}
