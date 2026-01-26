import ComposableArchitecture
import Toast

extension Effect {
  /// 에러 발생 시 토스트 노출
  public static func runWithToast(
    priority: TaskPriority? = nil,
    operation: @escaping @Sendable (_ send: Send<Action>) async throws -> Void,
    catch handler: (@Sendable (_ error: any Error, _ send: Send<Action>) async -> Void)? = nil,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) -> Self {
    return .run(
      priority: priority,
      operation: operation,
      catch: { error, send in
        @Dependency(ToastClient.self) var toastClient
        toastClient.showError(error)
        await handler?(error, send)
      },
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }
}
