import FeatureCore
import MainTab
import Onboarding
import SwiftUI

public struct AppView: View {
  @Bindable public var store: StoreOf<AppFeature>
  
  public init(store: StoreOf<AppFeature>) {
    self.store = store
  }
  
  public var body: some View {
    MainTabView(
      store: store.scope(state: \.mainTab, action: \.child.mainTab)
    )
    .sheet(isPresented: $store.isOnboardingPresented) {
      OnboardingView(
        store: store.scope(state: \.onboarding, action: \.child.onboarding)
      )
      .interactiveDismissDisabled(store.onboarding.isEnvironmentReady == false)
    }
    .tint(DesignTokens.Colors.accent)
    .background(DesignTokens.Colors.background)
    .frame(minWidth: 800, minHeight: 400)
  }
}
