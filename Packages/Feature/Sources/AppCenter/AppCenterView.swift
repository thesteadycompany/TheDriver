import FeatureCore
import SwiftUI

public struct AppCenterView: View {
  public let store: StoreOf<AppCenterFeature>
  
  public init(store: StoreOf<AppCenterFeature>) {
    self.store = store
  }
  
  public var body: some View {
    ScrollView {
      VStack(spacing: .zero) {
        
      }
    }
    .background(DesignTokens.Colors.background)
  }
}
