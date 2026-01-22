import FeatureCore
import SwiftUI

public struct MainTabView: View {
  public let store: StoreOf<MainTabFeature>
  
  public init(store: StoreOf<MainTabFeature>) {
    self.store = store
  }
  
  public var body: some View {
    VStack(spacing: .zero) {
      Text("Hello, MainTab")
    }
  }
}
