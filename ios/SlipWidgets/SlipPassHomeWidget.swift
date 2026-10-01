import AppIntents
import SwiftUI
import WidgetKit

struct PassWidgetEntry: TimelineEntry {
    let date: Date
    let passes: [WidgetPassSnapshot]
    let selectedIndex: Int

    var pass: WidgetPassSnapshot? {
        guard !passes.isEmpty else { return nil }
        return passes[min(max(0, selectedIndex), passes.count - 1)]
    }
}

struct PassWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> PassWidgetEntry {
        PassWidgetEntry(
            date: Date(),
            passes: [
                WidgetPassSnapshot(
                    id: "demo",
                    templateId: "upi",
                    displayName: "UPI PayPass",
                    subtitle: "rohit@icici",
                    qrPayload: "upi://pay",
                    accentRGB: "rgb(249, 115, 22)",
                    expiresAt: nil,
                    relevantAt: nil
                )
            ],
            selectedIndex: 0
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PassWidgetEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PassWidgetEntry>) -> Void) {
        let entry = currentEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func currentEntry() -> PassWidgetEntry {
        let passes = WidgetPassStore.load()
        return PassWidgetEntry(date: Date(), passes: passes, selectedIndex: WidgetPassStore.selectedIndex())
    }
}

struct CyclePassIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Slip Pass"
    static var description = IntentDescription("Show the next pass QR on the Slip home-screen widget.")

    func perform() async throws -> some IntentResult {
        WidgetPassStore.setSelectedIndex(WidgetPassStore.selectedIndex() + 1)
        WidgetCenter.shared.reloadTimelines(ofKind: "SlipPassHomeWidget")
        return .result()
    }
}

struct OpenBrightQRIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Bright QR"
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Pass ID")
    var passId: String

    init() { self.passId = "" }
    init(passId: String) { self.passId = passId }

    func perform() async throws -> some IntentResult {
        // URL open handled by openAppWhenRun + onOpenURL in app.
        return .result()
    }
}

struct SlipPassHomeWidget: Widget {
    let kind = "SlipPassHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PassWidgetProvider()) { entry in
            PassWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Slip Pass QR")
        .description("Lock Screen, StandBy, and Home Screen — tap to open a max-brightness QR.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryCircular])
    }
}

struct PassWidgetView: View {
    var entry: PassWidgetEntry

    var body: some View {
        if let pass = entry.pass {
            switch widgetFamily {
            case .accessoryCircular:
                accessoryCircular(pass)
            case .accessoryRectangular:
                accessoryRectangular(pass)
            case .systemSmall:
                small(pass)
            default:
                mediumLarge(pass)
            }
        } else {
            emptyState
        }
    }

    @Environment(\.widgetFamily) private var widgetFamily

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Slip")
                .font(.headline)
            Text("Unlock the app to publish pass QRs here.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func accessoryCircular(_ pass: WidgetPassSnapshot) -> some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "qrcode")
                .font(.title2)
        }
        .widgetURL(SlipDeepLink.brightQR(passId: pass.id))
    }

    private func accessoryRectangular(_ pass: WidgetPassSnapshot) -> some View {
        HStack(spacing: 8) {
            if let image = PassQRImage.uiImage(from: pass.qrPayload, dimension: 72) {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 36, height: 36)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(pass.displayName)
                    .font(.headline)
                    .lineLimit(1)
                Text(pass.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .widgetURL(SlipDeepLink.brightQR(passId: pass.id))
    }

    private func small(_ pass: WidgetPassSnapshot) -> some View {
        VStack(spacing: 8) {
            if let image = PassQRImage.uiImage(from: pass.qrPayload, dimension: 160) {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .padding(4)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
            }
            Text(pass.displayName)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .widgetURL(SlipDeepLink.brightQR(passId: pass.id))
    }

    private func mediumLarge(_ pass: WidgetPassSnapshot) -> some View {
        HStack(spacing: 12) {
            if let image = PassQRImage.uiImage(from: pass.qrPayload, dimension: 220) {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(maxWidth: widgetFamily == .systemLarge ? 180 : 120)
                    .padding(6)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 10))
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(pass.displayName)
                    .font(.headline)
                    .lineLimit(2)
                Text(pass.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                Text("\(entry.selectedIndex + 1)/\(max(entry.passes.count, 1))")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                HStack {
                    Button(intent: CyclePassIntent()) {
                        Label("Next", systemImage: "arrow.triangle.2.circlepath")
                            .font(.caption.weight(.semibold))
                    }
                    .tint(.primary)
                    Spacer(minLength: 0)
                    Link(destination: SlipDeepLink.brightQR(passId: pass.id)) {
                        Label("Bright", systemImage: "sun.max.fill")
                            .font(.caption.weight(.semibold))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
