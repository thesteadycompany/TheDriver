import SwiftUI

extension View {
  public func cardContainer() -> some View {
    modifier(CardContainerModifier())
  }
}

struct CardContainerModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(DesignTokens.Spacing.x4)
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
