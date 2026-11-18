import Foundation
import SwiftUI
import AppKit

struct WidgetEnvelope: Identifiable, Hashable, Codable {
  var id: String
  var name: String
  var tint: Int
  var left: Int
  var funded: Int
  var savings: Bool
  var leftLabel: String
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
  static let line = Color(red: 0.788, green: 0.690, blue: 0.541)
}

struct EnvelopeTile: View {
  let envelope: WidgetEnvelope
  let compact: Bool
  var body: some View {
    let tint = KraftTint(rawValue: envelope.tint)?.color ?? KraftTint.kraft.color
    let over = envelope.left < 0
    let ratio: CGFloat = {
      if envelope.funded <= 0 { return envelope.left > 0 ? 1 : 0 }
      return CGFloat(min(max(Double(envelope.left) / Double(max(envelope.funded, 1)), 0), 1))
    }()
    ZStack(alignment: .bottom) {
      RoundedRectangle(cornerRadius: compact ? 10 : 14, style: .continuous).fill(Kraft.card)
      GeometryReader { geo in
        VStack(spacing: 0) {
          Spacer(minLength: 0)
          Rectangle().fill(tint.opacity(0.45)).frame(height: max(geo.size.height * ratio, compact ? 6 : 10))
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: compact ? 10 : 14, style: .continuous))
      VStack {
        Capsule().fill(tint.opacity(0.85)).frame(height: compact ? 6 : 10)
          .padding(.horizontal, compact ? 10 : 16).padding(.top, compact ? 6 : 10)
        Spacer()
      }
      RoundedRectangle(cornerRadius: compact ? 10 : 14, style: .continuous).stroke(Kraft.line, lineWidth: 1.2)
      VStack(alignment: .leading, spacing: compact ? 2 : 6) {
        Text(envelope.name).font(.system(size: compact ? 11 : 15, weight: .semibold)).foregroundStyle(Kraft.ink).lineLimit(1)
        Spacer(minLength: 0)
        Text(envelope.savings ? "たまっている" : (over ? "使いすぎ" : "のこり"))
          .font(.system(size: compact ? 9 : 11, weight: .semibold))
          .foregroundStyle(over ? Kraft.stamp : Kraft.inkSoft)
        Text(envelope.leftLabel).font(.system(size: compact ? 14 : 22, weight: .bold))
          .foregroundStyle(over ? Kraft.stamp : Kraft.ink).minimumScaleFactor(0.6).lineLimit(1)
      }
      .padding(compact ? 8 : 12)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
  }
}

struct MediumWidgetView: View {
  let envelopes: [WidgetEnvelope]
  var body: some View {
    let items = Array(envelopes.prefix(4))
    let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: 2)
    LazyVGrid(columns: cols, spacing: 8) {
      ForEach(items) { env in EnvelopeTile(envelope: env, compact: true) }
    }
    .padding(10)
    .frame(width: 329, height: 155)
    .background(Kraft.paper)
  }
}

/// Same decode path as ios/FuutouWidget/EnvelopeModels.loadWidgetEnvelopes
func decodeEnvelopes(_ data: Data) throws -> [WidgetEnvelope] {
  try JSONDecoder().decode([WidgetEnvelope].self, from: data)
}

@main
struct SnapshotApp {
  static func main() {
    let args = CommandLine.arguments
    guard args.count >= 3 else {
      fputs("usage: widget_snapshot <out.png> <envelopes.json>\n", stderr)
      exit(1)
    }
    let outPath = args[1]
    let jsonPath = args[2]
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: jsonPath)),
          let rows = try? decodeEnvelopes(data), !rows.isEmpty else {
      fputs("error: failed to decode \(jsonPath)\n", stderr)
      exit(2)
    }
    fputs("decoded count=\(rows.count)\n", stderr)
    for e in rows.prefix(4) { fputs("\(e.name) \(e.leftLabel)\n", stderr) }

    let view = MediumWidgetView(envelopes: rows)
    let renderer = ImageRenderer(content: view)
    renderer.scale = 3
    guard let image = renderer.nsImage else {
      fputs("error: ImageRenderer failed\n", stderr)
      exit(3)
    }
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
      fputs("error: png encode failed\n", stderr)
      exit(4)
    }
    do {
      try png.write(to: URL(fileURLWithPath: outPath))
      fputs("wrote \(outPath) bytes=\(png.count)\n", stderr)
    } catch {
      fputs("error writing: \(error)\n", stderr)
      exit(5)
    }
  }
}
