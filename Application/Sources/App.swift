import App
import FeatureCore
import SwiftUI

@main
struct TheDriverApp: App {
  let store: StoreOf<AppFeature>
  
  init() {
    self.store = Store(initialState: AppFeature.State()) {
      AppFeature()
    }
  }
  var body: some Scene {
    WindowGroup {
      AppView(store: store)
    }
  }
}
