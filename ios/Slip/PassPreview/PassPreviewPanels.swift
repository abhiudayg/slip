import SwiftUI

struct QRPanel: View {
    let caption: String
    let alt: String
    let accent: Color

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 132, height: 132)
                    .shadow(color: accent.opacity(0.25), radius: 16, y: 6)
                Image(systemName: "qrcode")
                    .font(.slipSystem(size: 78, weight: .regular))
                    .foregroundStyle(.black.opacity(0.92))
            }
            Text(caption.uppercased())
                .font(SlipTheme.captionMono(10, weight: .bold))
                .foregroundStyle(accent.opacity(0.85))
                .tracking(1.2)
            if !alt.isEmpty {
                Text(alt)
                    .font(SlipTheme.captionMono(14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 16)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.15), Color.black.opacity(0.35)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .expandablePassCode(alt: alt, caption: caption)
    }
}

struct NFCPanel: View {
    let title: String
    let subtitle: String
    let tint: Color

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .strokeBorder(tint.opacity(0.25), lineWidth: 1)
                    .frame(width: 86, height: 86)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [tint.opacity(0.28), tint.opacity(0.06)],
                            center: .center,
                            startRadius: 4,
                            endRadius: 40
                        )
                    )
                    .frame(width: 68, height: 68)
                Image(systemName: "wave.3.right")
                    .font(.slipSystem(size: 26, weight: .semibold))
                    .foregroundStyle(tint)
                    .rotationEffect(.degrees(90))
            }
            Text(title)
                .font(SlipTheme.inter(14, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(SlipTheme.captionMono(11, weight: .medium))
                .foregroundStyle(tint.opacity(0.85))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.black.opacity(0.38))
    }
}

struct RouteConnector: View {
    let duration: String
    let tint: Color
    var icon: String = "airplane"

    var body: some View {
        VStack(spacing: 6) {
            Text(duration)
                .font(SlipTheme.captionMono(10, weight: .semibold))
                .foregroundStyle(tint.opacity(0.9))
            HStack(spacing: 0) {
                Circle()
                    .strokeBorder(tint, lineWidth: 2)
                    .frame(width: 8, height: 8)
                Rectangle()
                    .fill(
                        LinearGradient(colors: [tint.opacity(0.7), tint.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(height: 2)
                    .overlay(
                        Image(systemName: icon)
                            .font(.slipSystem(size: 11, weight: .bold))
                            .foregroundStyle(tint)
                            .offset(y: -10)
                    )
                Circle()
                    .fill(tint)
                    .frame(width: 8, height: 8)
            }
            .frame(width: 88)
        }
    }
}

struct BrandHeaderRow: View {
    let title: String
    let subtitle: String
    let logo: LogoTile
    let trailingLabel: String
    let trailingValue: String
    let accentSoft: Color
    var trailingColor: Color = .white

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(spacing: 10) {
                logo
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(SlipTheme.inter(16, weight: .bold))
                        .foregroundStyle(.white)
                    Text(subtitle.uppercased())
                        .font(SlipTheme.captionMono(10, weight: .semibold))
                        .foregroundStyle(accentSoft.opacity(0.9))
                        .tracking(0.8)
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 3) {
                MonoLabel(text: trailingLabel, color: accentSoft.opacity(0.7))
                Text(trailingValue)
                    .font(SlipTheme.captionMono(12, weight: .bold))
                    .foregroundStyle(trailingColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }
}

// MARK: - Airbnb

