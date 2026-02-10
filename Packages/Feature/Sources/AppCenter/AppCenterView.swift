import DevicePicker
import FeatureCore
import SwiftUI
import UniformTypeIdentifiers

@ViewAction(for: AppCenterFeature.self)
public struct AppCenterView: View {
  @Bindable public var store: StoreOf<AppCenterFeature>
  private let columns = Array(repeating: GridItem(.flexible()), count: 3)
  private let importableTypes: [UTType] = [UTType.applicationBundle, UTType(filenameExtension: "apk")].compactMap { $0 }
  
  public init(store: StoreOf<AppCenterFeature>) {
    self.store = store
  }
  
  public var body: some View {
    ScrollView {
      VStack(spacing: DesignTokens.Spacing.x8) {
        AppCenterUploadButton {
          send(.uploadTapped)
        } onDropAppURL: { url in
          send(.fileSelected(.success(url)))
        }
        
        LazyVGrid(columns: columns) {
          ForEach(store.models) { model in
            AppBundleCell(model: model) {
              send(.deviceTapped(model))
            } install: {
              send(.installTapped(model))
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
      allowedContentTypes: importableTypes
    ) {
      send(.fileSelected($0))
    }
    .sheet(
      item: $store.scope(state: \.devicePicker, action: \.child.devicePicker)
    ) {
      DevicePickerView(store: $0)
    }
  }
}
