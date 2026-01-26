import AppCenter
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
      TabSection("기기") {
        Tab("목록", systemImage: "iphone.motion", value: MainTabs.deviceList) {
          DeviceListView(
            store: store.scope(state: \.deviceList, action: \.child.deviceList)
          )
        }
        
        Tab("로그", systemImage: "apple.terminal", value: MainTabs.deviceLogging) {
          DeviceLoggingView(
            store: store.scope(state: \.deviceLogging, action: \.child.deviceLogging)
          )
        }
      }
      
      TabSection("앱") {
        Tab("앱 센터", systemImage: "app.fill", value: MainTabs.appCenter) {
          AppCenterView(
            store: store.scope(state: \.appCenter, action: \.child.appCenter)
          )
        }
      }
    }
    .tabViewStyle(.sidebarAdaptable)
    .background(DesignTokens.Colors.background)
  }
}
