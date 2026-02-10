import Entities
import FeatureCore
import SwiftUI

public struct AppBundleCellModel: Equatable, Identifiable, Sendable {
  public var id: String { appBundle.id }
  public let appBundle: AppBundle
  public var device: SimulatorDevice?
  
  public init(appBundle: AppBundle, device: SimulatorDevice? = nil) {
    self.appBundle = appBundle
    self.device = device
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
              ? DesignTokens.Colors.text
              : (model.device == nil ? DesignTokens.Colors.mutedText : DesignTokens.Colors.text)
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
    .disabled(model.appBundle.platform == .android)
  }
  
  private var installButton: some View {
    Button(action: install) {
      Text("설치 및 실행")
        .font(DesignTokens.Typography.button.font)
    }
    .buttonStyle(.borderedProminent)
    .tint(DesignTokens.Colors.accent)
    .disabled(model.appBundle.platform == .ios && model.device == nil)
  }

  private var deviceTitle: String {
    if model.appBundle.platform == .android {
      return "실행 중인 에뮬레이터 자동 선택"
    }
    return model.device?.name ?? "기기를 선택해 주세요"
  }
}
