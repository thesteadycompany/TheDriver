import FeatureCore
import SwiftUI

@ViewAction(for: AppCenterFeature.self)
public struct AppCenterView: View {
  public let store: StoreOf<AppCenterFeature>
  
  public init(store: StoreOf<AppCenterFeature>) {
    self.store = store
  }
  
  public var body: some View {
    ScrollView {
      VStack(spacing: .zero) {
        AppCenterUploadButton {
          send(.uploadTapped)
        }
      }
      .padding(.horizontal, DesignTokens.Spacing.x6)
      .padding(.vertical, DesignTokens.Spacing.x8)
    }
    .background(DesignTokens.Colors.background)
  }
}
