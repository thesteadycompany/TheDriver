import DependenciesMacros

@DependencyClient
public struct ToastClient: Sendable {
  public var show: @Sendable (Toast) -> Void
}
