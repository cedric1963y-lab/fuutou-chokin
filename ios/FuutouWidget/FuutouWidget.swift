import AppIntents
import SwiftUI
import WidgetKit

struct EnvelopeEntry: TimelineEntry {
  let date: Date
  let envelopes: [WidgetEnvelope]
  let selectedId: String?
}

struct Provider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> EnvelopeEntry {
    EnvelopeEntry(date: Date(), envelopes: sampleEnvelopes(), selectedId: sampleEnvelopes().first?.id)
  }

  func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> EnvelopeEntry {
    let rows = loadWidgetEnvelopes()
    return EnvelopeEntry(date: Date(), envelopes: rows, selectedId: configuration.envelope?.id ?? rows.first?.id)
  }

  func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<EnvelopeEntry> {
    let entry = await snapshot(for: configuration, in: context)
    let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
    return Timeline(entries: [entry], policy: .after(next))
  }
}

struct FuutouWidgetEntryView: View {
  @Environment(\.widgetFamily) var family
  var entry: EnvelopeEntry

  var body: some View {
    Group {
      switch family {
      case .systemSmall:
        smallView
      case .systemMedium:
        gridView(count: 4, columns: 2)
      case .systemLarge:
        gridView(count: 9, columns: 3)
      default:
        gridView(count: 4, columns: 2)
      }
    }
    .containerBackground(for: .widget) {
      Kraft.paper
    }
  }

  private var smallView: some View {
    let env = pickSmall()
    return Link(destination: envelopeURL(env.id)) {
      EnvelopeTile(envelope: env, compact: false)
        .padding(10)
    }
  }

  private func gridView(count: Int, columns: Int) -> some View {
    let items = Array(entry.envelopes.prefix(count))
    let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: columns)
    return LazyVGrid(columns: cols, spacing: 8) {
      ForEach(items) { env in
        Link(destination: envelopeURL(env.id)) {
          EnvelopeTile(envelope: env, compact: true)
        }
      }
    }
    .padding(10)
  }

  private func pickSmall() -> WidgetEnvelope {
    if let id = entry.selectedId, let match = entry.envelopes.first(where: { $0.id == id }) {
      return match
    }
    return entry.envelopes.first ?? sampleEnvelopes()[0]
  }
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
      RoundedRectangle(cornerRadius: compact ? 10 : 14, style: .continuous)
        .fill(Kraft.card)
      GeometryReader { geo in
        VStack(spacing: 0) {
          Spacer(minLength: 0)
          Rectangle()
            .fill(tint.opacity(0.45))
            .frame(height: max(geo.size.height * ratio, compact ? 6 : 10))
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: compact ? 10 : 14, style: .continuous))

      // 封筒のふたライン
      VStack {
        Capsule()
          .fill(tint.opacity(0.85))
          .frame(height: compact ? 6 : 10)
          .padding(.horizontal, compact ? 10 : 16)
          .padding(.top, compact ? 6 : 10)
        Spacer()
      }

      RoundedRectangle(cornerRadius: compact ? 10 : 14, style: .continuous)
        .stroke(Kraft.line, lineWidth: 1.2)

      VStack(alignment: .leading, spacing: compact ? 2 : 6) {
        Text(envelope.name)
          .font(.custom("KiwiMaru-Medium", size: compact ? 11 : 15))
          .foregroundStyle(Kraft.ink)
          .lineLimit(1)
        Spacer(minLength: 0)
        Text(envelope.savings ? "たまっている" : (over ? "使いすぎ" : "のこり"))
          .font(.system(size: compact ? 9 : 11, weight: .semibold))
          .foregroundStyle(over ? Kraft.stamp : Kraft.inkSoft)
        Text(envelope.leftLabel)
          .font(.custom("KiwiMaru-Medium", size: compact ? 14 : 22))
          .foregroundStyle(over ? Kraft.stamp : Kraft.ink)
          .minimumScaleFactor(0.6)
          .lineLimit(1)
      }
      .padding(compact ? 8 : 12)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
  }
}

@main
struct FuutouEnvelopesWidget: Widget {
  let kind: String = "FuutouEnvelopesWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
      FuutouWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("封筒ののこり")
    .description("封筒ごとの残高をホーム画面に表示します。小・中・大で 1・4・9 枚まで。")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}
