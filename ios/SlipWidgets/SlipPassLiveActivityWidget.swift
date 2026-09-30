import ActivityKit
import SwiftUI
import WidgetKit

struct SlipPassLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SlipPassActivityAttributes.self) { context in
            lockScreenView(context: context)
                .activityBackgroundTint(Color(red: 0.07, green: 0.04, blue: 0.09))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: islandIcon(for: context.attributes.templateId))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color(red: 0.82, green: 0.73, blue: 1.0))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.progress, format: .percent.precision(.fractionLength(0)))
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.passTitle)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.statusLine)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(context.state.detailLine)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.75))
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                Image(systemName: islandIcon(for: context.attributes.templateId))
                    .foregroundStyle(Color(red: 0.82, green: 0.73, blue: 1.0))
            } compactTrailing: {
                Text(compactTrailing(context))
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
            } minimal: {
                Image(systemName: islandIcon(for: context.attributes.templateId))
                    .foregroundStyle(Color(red: 0.82, green: 0.73, blue: 1.0))
            }
        }
    }

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<SlipPassActivityAttributes>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: islandIcon(for: context.attributes.templateId))
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color(red: 0.82, green: 0.73, blue: 1.0))
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.white.opacity(0.08)))

            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.passTitle)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(context.state.statusLine)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(red: 0.82, green: 0.73, blue: 1.0))
                    .lineLimit(1)
                Text(context.state.detailLine)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
    }

    private func compactTrailing(_ context: ActivityViewContext<SlipPassActivityAttributes>) -> String {
        let route = context.attributes.routeOrVenue
        if route.count <= 8 { return route }
        return String(route.prefix(6)) + "…"
    }

    private func islandIcon(for templateId: String) -> String {
        switch templateId {
        case "irctc", "redbus": return "train.side.front.car"
        case "indigo": return "airplane"
        case "namma-metro": return "tram.fill"
        case "bookmyshow", "district": return "ticket.fill"
        case "airbnb": return "house.fill"
        case "upi": return "qrcode"
        default: return "wallet.pass.fill"
        }
    }
}
