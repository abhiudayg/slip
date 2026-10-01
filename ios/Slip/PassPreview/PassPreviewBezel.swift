import SwiftUI

/// Mock iPhone frame with Dynamic Island — frames the Wallet pass preview.
struct PassDeviceBezel<Content: View>: View {
    var showsIsland: Bool = true
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            if showsIsland {
                Capsule(style: .continuous)
                    .fill(Color.black)
                    .frame(width: 118, height: 34)
                    .overlay(
                        HStack(spacing: 8) {
                            Circle().fill(Color.black.opacity(0.001)).frame(width: 10, height: 10)
                            Spacer(minLength: 0)
                            Circle()
                                .fill(Color(white: 0.12))
                                .frame(width: 12, height: 12)
                                .overlay(Circle().strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5))
                        }
                        .padding(.horizontal, 14)
                    )
                    .padding(.bottom, 10)
                    .accessibilityHidden(true)
            }

            content
                .padding(.horizontal, 10)
                .padding(.vertical, 12)
        }
        .padding(.horizontal, 10)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(
            RoundedRectangle(cornerRadius: 42, style: .continuous)
                .fill(Color(red: 0.07, green: 0.07, blue: 0.09))
                .overlay(
                    RoundedRectangle(cornerRadius: 42, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.28), Color.white.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: .black.opacity(0.35), radius: 24, y: 14)
        )
        .padding(.horizontal, 4)
    }
}
