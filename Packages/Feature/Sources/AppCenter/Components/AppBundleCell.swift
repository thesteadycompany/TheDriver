import Entities
import FeatureCore
import SwiftUI

public struct AppBundleCellModel: Equatable, Identifiable, Sendable {
  public var id: String { appBundle.id }
  public let appBundle: AppBundle
  public var iOSDevice: SimulatorDevice?
  public var androidDevice: EmulatorDevice?

  public init(
    appBundle: AppBundle,
    iOSDevice: SimulatorDevice? = nil,
    androidDevice: EmulatorDevice? = nil
  ) {
    self.appBundle = appBundle
    self.iOSDevice = iOSDevice
    self.androidDevice = androidDevice
  }
}

struct AppBundleCell: View {
  let model: AppBundleCellModel
  let device: () -> Void
  let install: () -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: DesignTokens.Spacing.x4) {
      HStack(spacing: DesignTokens.Spacing.x3) {
        appIcon
        
        titleView
      }
      
      HStack(spacing: DesignTokens.Spacing.x3) {
        deviceButton
        
        installButton
      }
    }
    .cardContainer()
  }
  
  private var appIcon: some View {
    Image(
      nsImage: NSWorkspace.shared.icon(forFile: model.appBundle.url.path)
    )
    .resizable()
    .frame(
      width: DesignTokens.Spacing.x16,
      height: DesignTokens.Spacing.x16
    )
  }
  
  private var titleView: some View {
    Text(model.appBundle.name)
      .font(DesignTokens.Typography.headline.font)
      .foregroundStyle(DesignTokens.Colors.text)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
  
  private var deviceButton: some View {
    Button(action: device) {
      HStack {
        Text(deviceTitle)
          .font(DesignTokens.Typography.body.font)
          .foregroundStyle(
            model.appBundle.platform == .android
              ? (model.androidDevice == nil ? DesignTokens.Colors.mutedText : DesignTokens.Colors.text)
              : (model.iOSDevice == nil ? DesignTokens.Colors.mutedText : DesignTokens.Colors.text)
          )
          .frame(maxWidth: .infinity, alignment: .leading)
        
        Image(systemName: "chevron.down")
          .font(DesignTokens.Typography.body.font)
          .foregroundStyle(DesignTokens.Colors.border)
      }
      .padding(DesignTokens.Spacing.x2)
    }
    .background {
      RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
        .fill(DesignTokens.Colors.surface)
    }
    .overlay {
      RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
        .stroke(DesignTokens.Colors.border, lineWidth: 1)
    }
  }
  
  private var installButton: some View {
    Button(action: install) {
      Text("설치 및 실행")
        .font(DesignTokens.Typography.button.font)
    }
    .buttonStyle(.borderedProminent)
    .tint(DesignTokens.Colors.accent)
    .disabled(isInstallDisabled)
  }

  private var deviceTitle: String {
    if model.appBundle.platform == .android {
      return model.androidDevice?.name ?? "기기를 선택해 주세요"
    }
    return model.iOSDevice?.name ?? "기기를 선택해 주세요"
  }

  private var isInstallDisabled: Bool {
    switch model.appBundle.platform {
    case .ios:
      model.iOSDevice == nil
    case .android:
      model.androidDevice == nil
    }
  }
}
