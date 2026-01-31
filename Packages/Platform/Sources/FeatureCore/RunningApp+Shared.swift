import Entities
import Sharing

extension SharedKey where Self == InMemoryKey<RunningApp?> {
  public static var runningApp: Self { .inMemory("runningApp") }
}
