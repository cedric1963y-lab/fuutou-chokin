import Foundation
import SwiftUI

let fuutouAppGroupId = "group.jp.fuutouchokin.app"
let fuutouEnvelopesKey = "envelopes_json"
let fuutouURLScheme = "fuutouchokin"

struct WidgetEnvelope: Identifiable, Hashable, Codable {
  var id: String
  var name: String
  var tint: Int
  var left: Int
  var funded: Int
  var savings: Bool
  var leftLabel: String

  enum CodingKeys: String, CodingKey {
    case id, name, tint, left, funded, savings, leftLabel
  }
}

enum KraftTint: Int {
  case kraft, clay, mustard, sage, slate, rose, ivory, plum

  var color: Color {
    switch self {
    case .kraft: return Color(red: 0.780, green: 0.604, blue: 0.392)
    case .clay: return Color(red: 0.749, green: 0.451, blue: 0.329)
    case .mustard: return Color(red: 0.839, green: 0.675, blue: 0.306)
    case .sage: return Color(red: 0.592, green: 0.663, blue: 0.514)
    case .slate: return Color(red: 0.510, green: 0.600, blue: 0.682)
    case .rose: return Color(red: 0.812, green: 0.584, blue: 0.565)
    case .ivory: return Color(red: 0.914, green: 0.863, blue: 0.741)
    case .plum: return Color(red: 0.655, green: 0.525, blue: 0.604)
    }
  }
}

enum Kraft {
  static let paper = Color(red: 0.918, green: 0.859, blue: 0.753)
  static let card = Color(red: 0.965, green: 0.933, blue: 0.867)
  static let ink = Color(red: 0.231, green: 0.165, blue: 0.118)
  static let inkSoft = Color(red: 0.478, green: 0.384, blue: 0.314)
  static let stamp = Color(red: 0.706, green: 0.267, blue: 0.180)
  static let leaf = Color(red: 0.369, green: 0.478, blue: 0.298)
  static let line = Color(red: 0.788, green: 0.690, blue: 0.541)
}

func loadWidgetEnvelopes() -> [WidgetEnvelope] {
  let defaults = UserDefaults(suiteName: fuutouAppGroupId)
  guard let raw = defaults?.string(forKey: fuutouEnvelopesKey),
        let data = raw.data(using: .utf8),
        let rows = try? JSONDecoder().decode([WidgetEnvelope].self, from: data)
  else {
    return sampleEnvelopes()
  }
  return rows
}

func sampleEnvelopes() -> [WidgetEnvelope] {
  [
    WidgetEnvelope(id: "food", name: "食費", tint: 0, left: 18420, funded: 32000, savings: false, leftLabel: "¥18,420"),
    WidgetEnvelope(id: "daily", name: "日用品", tint: 3, left: 6120, funded: 8000, savings: false, leftLabel: "¥6,120"),
    WidgetEnvelope(id: "eatout", name: "外食", tint: 1, left: 2550, funded: 10000, savings: false, leftLabel: "¥2,550"),
    WidgetEnvelope(id: "fun", name: "娯楽", tint: 2, left: 7700, funded: 10000, savings: false, leftLabel: "¥7,700"),
    WidgetEnvelope(id: "transit", name: "交通費", tint: 4, left: 4300, funded: 6000, savings: false, leftLabel: "¥4,300"),
    WidgetEnvelope(id: "med", name: "医療費", tint: 5, left: 5000, funded: 5000, savings: false, leftLabel: "¥5,000"),
    WidgetEnvelope(id: "kids", name: "子ども", tint: 4, left: 3200, funded: 6000, savings: false, leftLabel: "¥3,200"),
    WidgetEnvelope(id: "gift", name: "交際費", tint: 7, left: 4100, funded: 5000, savings: false, leftLabel: "¥4,100"),
    WidgetEnvelope(id: "savings", name: "貯金", tint: 6, left: 122300, funded: 20000, savings: true, leftLabel: "¥122,300"),
  ]
}

func envelopeURL(_ id: String) -> URL {
  URL(string: "\(fuutouURLScheme)://envelope/\(id)")!
}

func homeURL() -> URL {
  URL(string: "\(fuutouURLScheme)://home")!
}
