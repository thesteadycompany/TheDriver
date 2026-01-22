import Dependencies

extension SimulatorClient: DependencyKey {
  public static let liveValue = SimulatorClient(
    requestDevices: {
      // TODO: - Request
      return []
    }
  )
}
