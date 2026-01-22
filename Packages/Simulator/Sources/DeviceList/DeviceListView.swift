import FeatureCore
import SwiftUI

@ViewAction(for: DeviceListFeature.self)
public struct DeviceListView: View {
  public let store: StoreOf<DeviceListFeature>
  private let columns = Array(repeating: GridItem(.flexible()), count: 3)
  
  public init(store: StoreOf<DeviceListFeature>) {
    self.store = store
  }
  
  public var body: some View {
    ScrollView {
      LazyVGrid(columns: columns) {
        ForEach(store.devices) { device in
          DeviceCell(device: device)
        }
      }
    }
    .onAppear {
      send(.onAppear)
    }
  }
}
