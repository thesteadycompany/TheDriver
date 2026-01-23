import FeatureCore
import SwiftUI

@ViewAction(for: DeviceLoggingFeature.self)
public struct DeviceLoggingView: View {
  public let store: StoreOf<DeviceLoggingFeature>
  
  public init(store: StoreOf<DeviceLoggingFeature>) {
    self.store = store
  }
  
  public var body: some View {
    VStack(spacing: .zero) {
      
    }
    .onAppear {
      send(.onAppear)
    }
  }
}
