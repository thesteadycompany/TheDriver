import FeatureCore
import SwiftUI

struct AppCenterUploadButton: View {
  let action: () -> Void
  
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
        .fill(DesignTokens.Colors.surface)
    }
    .overlay {
      RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
        .stroke(DesignTokens.Colors.border, lineWidth: 1)
    }
  }
}
