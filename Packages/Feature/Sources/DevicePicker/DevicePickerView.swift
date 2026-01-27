import FeatureCore
import SwiftUI

@ViewAction(for: DevicePickerFeature.self)
public struct DevicePickerView: View {
  public let store: StoreOf<DevicePickerFeature>
  
  public init(store: StoreOf<DevicePickerFeature>) {
    self.store = store
  }
  
  public var body: some View {
    VStack {
      DevicePickerHeaderView(
        appBundle: store.appBundle,
        isEnabled: store.current != nil
      ) {
        send(.saveTapped)
      }
      .padding(.horizontal, DesignTokens.Spacing.x6)
      
      ScrollView {
        ForEach(store.devices) { device in
          DevicePickerCell(
            device: device,
            isCurrent: store.current == device
          ) {
            send(.deviceTapped(device))
          }
          .padding(.horizontal, DesignTokens.Spacing.x6)
        }
      }
    }
    .padding(.vertical, DesignTokens.Spacing.x8)
    .background(DesignTokens.Colors.background)
    .onAppear {
      send(.onAppear)
    }
  }
}
