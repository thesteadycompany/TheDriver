import Dependencies
import SwiftUI

@MainActor
final class ToastAnimator: ObservableObject {
  @Published var isPresented = false
  
  func show() {
    @Dependency(\.continuousClock) var clock
    Task { @MainActor in
      try? await clock.sleep(for: .milliseconds(50))
      isPresented = true
    }
  }
  
  func dismiss() async {
    @Dependency(\.continuousClock) var clock
    isPresented = false
    try? await clock.sleep(for: .milliseconds(400))
  }
}

struct ToastContainer: View {
  let toast: Toast
  @ObservedObject var animator: ToastAnimator
  
  var body: some View {
    ToastView(toast: toast, isPresented: $animator.isPresented)
      .onAppear {
        animator.show()
      }
  }
}
