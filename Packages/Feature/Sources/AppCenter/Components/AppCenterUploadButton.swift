import FeatureCore
import Foundation
import SwiftUI

struct AppCenterUploadButton: View {
  let action: () -> Void
  let onDropAppURL: (URL) -> Void
  
  @State private var isDropTargeted = false
  
  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: DesignTokens.Spacing.x2) {
        Text("파일을 업로드해 주세요")
          .font(DesignTokens.Typography.headline.font)
          .foregroundStyle(DesignTokens.Colors.text)
        
        Text("지원하는 파일 (.app)")
          .font(DesignTokens.Typography.body.font)
          .foregroundStyle(DesignTokens.Colors.mutedText)
      }
      
      Spacer()
      
      Button(action: action) {
        Image(systemName: "plus")
          .font(DesignTokens.Typography.title2.font)
          .foregroundStyle(DesignTokens.Colors.accent)
          .padding(DesignTokens.Spacing.x3)
      }
      .clipShape(.circle)
      .background {
        Circle()
          .fill(DesignTokens.Colors.surfaceAccent)
      }
    }
    .multilineTextAlignment(.center)
    .frame(maxWidth: .infinity)
    .padding(DesignTokens.Spacing.x6)
    .background {
      RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
        .fill(
          isDropTargeted
            ? DesignTokens.Colors.surfaceAccent.opacity(0.12)
            : DesignTokens.Colors.surface
        )
    }
    .overlay {
      RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
        .stroke(
          isDropTargeted ? DesignTokens.Colors.accent : DesignTokens.Colors.border,
          lineWidth: isDropTargeted ? 2 : 1
        )
    }
    .accessibilityIdentifier("appcenter.upload.dropzone")
    .accessibilityValue(isDropTargeted ? "targeted" : "idle")
    .dropDestination(for: URL.self) { items, _ in
      guard let appURL = items.first(where: { $0.pathExtension.lowercased() == "app" }) else {
        return false
      }
      onDropAppURL(appURL)
      return true
    } isTargeted: { isTargeted in
      isDropTargeted = isTargeted
    }
  }
}
