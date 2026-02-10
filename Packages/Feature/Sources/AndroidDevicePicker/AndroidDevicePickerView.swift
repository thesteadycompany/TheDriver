import FeatureCore
import SwiftUI

@ViewAction(for: AndroidDevicePickerFeature.self)
public struct AndroidDevicePickerView: View {
  public let store: StoreOf<AndroidDevicePickerFeature>

  public init(store: StoreOf<AndroidDevicePickerFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack {
      AndroidDevicePickerHeaderView(
        appBundle: store.appBundle,
        isEnabled: store.current != nil
      ) {
        send(.saveTapped)
      }
      .padding(.horizontal, DesignTokens.Spacing.x6)

      ScrollView {
        ForEach(store.devices) { device in
          AndroidDevicePickerCell(
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
