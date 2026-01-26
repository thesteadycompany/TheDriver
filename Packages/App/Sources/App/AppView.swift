import FeatureCore
import MainTab
import SwiftUI

public struct AppView: View {
  public let store: StoreOf<AppFeature>
  
  public init(store: StoreOf<AppFeature>) {
    self.store = store
  }
  
  public var body: some View {
    MainTabView(
      store: store.scope(state: \.mainTab, action: \.mainTab)
    )
    .tint(DesignTokens.Colors.accent)
    .background(DesignTokens.Colors.background)
    .frame(minWidth: 800, minHeight: 400)
  }
}
