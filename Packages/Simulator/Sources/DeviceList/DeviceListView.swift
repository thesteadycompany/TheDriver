import FeatureCore
import SwiftUI

@ViewAction(for: DeviceListFeature.self)
public struct DeviceListView: View {
  public let store: StoreOf<DeviceListFeature>
  
  public init(store: StoreOf<DeviceListFeature>) {
    self.store = store
  }
  
  public var body: some View {
    List {
      ForEach(store.devices) { device in
        DeviceCell(device: device)
      }
    }
    .onAppear {
      send(.onAppear)
    }
  }
}
