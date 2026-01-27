import FeatureCore
import SwiftUI

@ViewAction(for: AppCenterFeature.self)
public struct AppCenterView: View {
  @Bindable public var store: StoreOf<AppCenterFeature>
  private let columns = Array(repeating: GridItem(.flexible()), count: 3)
  
  public init(store: StoreOf<AppCenterFeature>) {
    self.store = store
  }
  
  public var body: some View {
    ScrollView {
      VStack(spacing: DesignTokens.Spacing.x8) {
        AppCenterUploadButton {
          send(.uploadTapped)
        }
        
        LazyVGrid(columns: columns) {
          ForEach(store.models) { model in
            AppBundleCell(model: model) {
              send(.deviceTapped(model.appBundle))
            } install: {
              send(.installTapped(model.appBundle))
            }
          }
        }
      }
      .padding(.horizontal, DesignTokens.Spacing.x6)
      .padding(.vertical, DesignTokens.Spacing.x8)
    }
    .background(DesignTokens.Colors.background)
    .fileImporter(
      isPresented: $store.isFileImporterPresented,
      allowedContentTypes: [.applicationBundle]
    ) {
      send(.fileSelected($0))
    }
  }
}
