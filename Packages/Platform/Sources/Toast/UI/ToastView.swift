import DesignSystem
import SwiftUI

struct ToastView: View {
  let toast: Toast
  @Binding var isPresented: Bool
  
  var body: some View {
    VStack {
      ToastContentView(toast: toast)
        .shadow(
          color: .black.opacity(0.1),
          radius: DesignTokens.Radius.card,
          x: 0,
          y: 2
        )
        .padding(.horizontal, DesignTokens.Spacing.x4)
        .padding(.top, DesignTokens.Spacing.x9)
      
      Spacer()
    }
    .offset(y: isPresented ? 0 : -200)
    .opacity(isPresented ? 1 : 0)
    .animation(.spring(duration: 0.4), value: isPresented)
  }
}
