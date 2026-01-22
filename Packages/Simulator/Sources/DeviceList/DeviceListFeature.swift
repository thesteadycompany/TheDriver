import FeatureCore
import Foundation

@Reducer
public struct DeviceListFeature {
  @ObservableState
  public struct State: Equatable {
    public init() {}
  }
  
  @CasePathable
  public enum Action {}
  
  public init() {}
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      return .none
    }
  }
}
