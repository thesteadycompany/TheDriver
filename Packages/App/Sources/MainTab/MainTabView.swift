import DeviceList
import FeatureCore
import SwiftUI

public struct MainTabView: View {
  @Bindable public var store: StoreOf<MainTabFeature>
  
  public init(store: StoreOf<MainTabFeature>) {
    self.store = store
  }
  
  public var body: some View {
    TabView(selection: $store.currentTab) {
      Tab("기기 목록", systemImage: "iphone.motion", value: .deviceList) {
        DeviceListView(
          store: store.scope(state: \.deviceList, action: \.child.deviceList)
        )
      }
    }
    .tabViewStyle(.sidebarAdaptable)
  }
}
