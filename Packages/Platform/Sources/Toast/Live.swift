import AppKit
import Dependencies
import SwiftUI

extension ToastClient: DependencyKey {
  public static let liveValue = ToastClient { toast in
    Task { @MainActor in
      Provider.shared.show(toast)
    }
  }
  
  public func callAsFunction(_ toast: Toast) -> Void {
    show(toast)
  }
  
  public func showPlain(_ message: String) {
    show(.plain(message))
  }
  
  public func showSuccess(_ message: String) {
    show(.success(message))
  }
  
  public func showWarning(_ message: String) {
    show(.warning(message))
  }
  
  public func showError(_ error: Error) {
    show(.failure(error.localizedDescription))
  }
}

@MainActor
private final class Provider {
  static let shared = Provider()
  
  private var toastPanel: PassThroughPanel?
  private var dismissTask: Task<Void, Never>?
  private var showTask: Task<Void, Never>?
  private var animator: ToastAnimator?
  
  func show(_ toast: Toast) {
    showTask?.cancel()
    showTask = Task { @MainActor in
      if toastPanel != nil { await dismiss() }
      if Task.isCancelled { return }
      await showToast(toast)
    }
  }
  
  private func showToast(_ toast: Toast) async {
    guard let screen = preferredScreen() else { return }
    let panel = PassThroughPanel(
      contentRect: screen.frame,
      backing: .buffered,
      defer: false
    )
    panel.level = .statusBar
    panel.backgroundColor = .clear
    panel.isOpaque = false
    panel.hasShadow = false
    panel.ignoresMouseEvents = true
    panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    panel.isReleasedWhenClosed = false
    
    let animator = ToastAnimator()
    let container = ToastContainer(toast: toast, animator: animator)
    let hostingView = NSHostingView(rootView: container)
    hostingView.translatesAutoresizingMaskIntoConstraints = true
    hostingView.autoresizingMask = [.width, .height]
    hostingView.frame = panel.contentView?.bounds ?? panel.frame
    
    let content = NSView(frame: panel.contentView?.bounds ?? panel.frame)
    content.wantsLayer = true
    content.layer?.backgroundColor = NSColor.clear.cgColor
    
    content.addSubview(hostingView)
    panel.contentView = content
    
    panel.orderFrontRegardless()
    
    toastPanel = panel
    self.animator = animator
    
    dismissTask?.cancel()
    dismissTask = Task { @MainActor in
      @Dependency(\.continuousClock) var clock
      try? await clock.sleep(for: toast.delay.seconds)
      if Task.isCancelled { return }
      await dismiss()
    }
  }
  
  private func dismiss() async {
    await animator?.dismiss()
    removeCurrentImmediately()
  }
  
  private func removeCurrentImmediately() {
    dismissTask?.cancel()
    dismissTask = nil
    
    animator?.isPresented = false
    animator = nil
    
    toastPanel?.orderOut(nil)
    toastPanel?.contentView = nil
    toastPanel = nil
  }
  
  private func preferredScreen() -> NSScreen? {
    if let window = NSApp.keyWindow ?? NSApp.mainWindow, let screen = window.screen {
      return screen
    }
    return NSScreen.main
  }
}

private final class PassThroughPanel: NSPanel {
  override var canBecomeKey: Bool { false }
  override var canBecomeMain: Bool { false }
  
  convenience init(contentRect: CGRect, backing: NSWindow.BackingStoreType, defer: Bool) {
    self.init(
      contentRect: contentRect,
      styleMask: [.borderless, .nonactivatingPanel],
      backing: backing,
      defer: `defer`
    )
    isFloatingPanel = true
    hidesOnDeactivate = false
  }
}
