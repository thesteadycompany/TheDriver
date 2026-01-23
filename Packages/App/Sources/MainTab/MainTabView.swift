import DeviceList
import DeviceLogging
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
      Tab("기기 로그", systemImage: "apple.terminal", value: .deviceLogging) {
        DeviceLoggingView(
          store: store.scope(state: \.deviceLogging, action: \.child.deviceLogging)
        )
      }
    }
    .tabViewStyle(.sidebarAdaptable)
  }
}
