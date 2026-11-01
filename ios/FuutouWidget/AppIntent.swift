import AppIntents
import WidgetKit

struct EnvelopeEntity: AppEntity {
  typealias ID = String
  var id: String
  var name: String

  static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "封筒")
  static var defaultQuery = EnvelopeEntityQuery()

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(name)")
  }
}

struct EnvelopeEntityQuery: EntityQuery {
  func entities(for identifiers: [EnvelopeEntity.ID]) async throws -> [EnvelopeEntity] {
    let all = loadWidgetEnvelopes()
    return identifiers.compactMap { id in
      guard let row = all.first(where: { $0.id == id }) else { return nil }
      return EnvelopeEntity(id: row.id, name: row.name)
    }
  }

  func suggestedEntities() async throws -> [EnvelopeEntity] {
    loadWidgetEnvelopes().map { EnvelopeEntity(id: $0.id, name: $0.name) }
  }

  func defaultResult() async -> EnvelopeEntity? {
    let all = loadWidgetEnvelopes()
    guard let first = all.first else { return nil }
    return EnvelopeEntity(id: first.id, name: first.name)
  }
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "封筒貯金ウィジェット"
  static var description = IntentDescription("ホーム画面に封筒の残りを表示します。小さいサイズでは表示する封筒を選べます。")

  @Parameter(title: "表示する封筒（小サイズ）")
  var envelope: EnvelopeEntity?
}
