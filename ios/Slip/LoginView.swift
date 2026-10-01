import AuthenticationServices
import SwiftUI

/// Launch screen matching Stitch `Login & Onboarding - Slip`
/// (projects/6057453755376154551/screens/107799e3dd8840868bf218ee8a5673f5).
struct LoginView: View {
    @EnvironmentObject private var auth: AuthSession
    @EnvironmentObject private var model: AppModel

    @State private var localError: String?

    var body: some View {
        ZStack {
            MeshBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    brandHeader
                        .padding(.top, 12)

                    passStackPreview
                        .padding(.top, 24)
                        .padding(.bottom, 8)

                    authDock
                        .padding(.top, 20)
                        .padding(.bottom, 28)
                }
                .padding(.horizontal, 20)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await auth.refreshCloud(using: model.api)
        }
    }

    // MARK: - Brand

    private var brandHeader: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(SlipTheme.indigo.opacity(0.28))
                    .frame(width: 144, height: 144)
                    .blur(radius: 28)
                Ellipse()
                    .fill(SlipTheme.accent.opacity(0.18))
                    .frame(width: 112, height: 80)
                    .offset(y: 28)
                    .blur(radius: 22)

                SlipBrandMark(size: 96)
                    .shadow(color: .black.opacity(0.45), radius: 18, y: 10)
            }
            .padding(.bottom, 4)

            HStack(spacing: 6) {
                Text("Slip")
                    .font(.system(size: 34, weight: .bold))
                    .tracking(-0.8)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, SlipTheme.accentSoft, SlipTheme.muted],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("iOS 27")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(0.4)
                    .textCase(.uppercase)
                    .foregroundStyle(SlipTheme.accentSoft)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(SlipTheme.indigo.opacity(0.35)))
            }

            Text("Daily QRs. Slipped into Apple Wallet.")
                .font(.system(size: 17, weight: .semibold))
                .tracking(-0.2)
                .foregroundStyle(SlipTheme.ink)
                .multilineTextAlignment(.center)

            Text("Zero turnstile friction for Namma Metro, Cult.fit, IRCTC, IndiGo & UPI. Ready on Lock Screen.")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(SlipTheme.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)

            cloudStatusChip
                .padding(.top, 10)
        }
        .frame(maxWidth: .infinity)
    }

    private var cloudStatusChip: some View {
        Group {
            switch auth.cloudStatus {
            case .checking:
                StatusPill(title: "Checking cloud…", tint: SlipTheme.amber)
            case .connected(let count):
                StatusPill(title: "Cloud · \(count) brands", tint: SlipTheme.upiGreen, filled: false)
            case .unreachable:
                Button {
                    Task { await auth.refreshCloud(using: model.api) }
                } label: {
                    StatusPill(title: "Cloud offline · retry", tint: SlipTheme.magenta)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Pass stack (Stitch 2.5D preview)

    private var passStackPreview: some View {
        ZStack {
            Ellipse()
                .fill(SlipTheme.indigo.opacity(0.22))
                .frame(width: 260, height: 90)
                .offset(y: -70)
                .blur(radius: 36)

            irctcBackCard
                .scaleEffect(0.90)
                .opacity(0.42)
                .offset(y: -8)

            cultMidCard
                .scaleEffect(0.95)
                .opacity(0.82)
                .offset(y: 14)

            nammaHeroCard
                .offset(y: 42)
        }
        .frame(height: 220)
        .frame(maxWidth: 360)
    }

    private var irctcBackCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("IRCTC TICKET", systemImage: "tram.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(SlipTheme.accentSoft)
                Spacer()
                Text("PNR 4829-10928")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SlipTheme.muted)
            }
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("SBC").font(.system(size: 17, weight: .bold))
                    Text("06:00 AM").font(.system(size: 12)).foregroundStyle(SlipTheme.muted)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(SlipTheme.muted.opacity(0.6))
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("MAS").font(.system(size: 17, weight: .bold))
                    Text("10:45 AM").font(.system(size: 12)).foregroundStyle(SlipTheme.muted)
                }
            }
            .foregroundStyle(SlipTheme.ink)
        }
        .padding(14)
        .background(previewGlass(corner: 16))
        .padding(.horizontal, 16)
    }

    private var cultMidCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle().fill(SlipTheme.magenta.opacity(0.28)).frame(width: 24, height: 24)
                        Image(systemName: "figure.run")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(SlipTheme.magenta)
                    }
                    Text("Cult.fit Elite")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(SlipTheme.ink)
                }
                Spacer()
                Text("UNLIMITED CHECK-IN")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(SlipTheme.magenta)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(SlipTheme.magenta.opacity(0.28)))
            }
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Home Center")
                        .font(.system(size: 12))
                        .foregroundStyle(SlipTheme.muted)
                    Text("Indiranagar 100ft Rd")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(SlipTheme.ink)
                }
                Spacer()
                Label("Tap to show", systemImage: "qrcode")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SlipTheme.accentSoft)
            }
        }
        .padding(14)
        .background(previewGlass(corner: 16))
        .padding(.horizontal, 8)
    }

    private var nammaHeroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(SlipTheme.indigo).frame(width: 32, height: 32)
                        Image(systemName: "tram.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Namma Metro")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(.white)
                            Circle()
                                .fill(SlipTheme.upiGreen)
                                .frame(width: 7, height: 7)
                        }
                        Text("Purple Line Transit")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(SlipTheme.accentSoft)
                    }
                }
                Spacer()
                HStack(spacing: 6) {
                    Text("BAL")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(SlipTheme.muted)
                    Text("₹420.00")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.10)))
            }

            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "wave.3.right")
                        .foregroundStyle(SlipTheme.accentSoft)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            Circle().fill(SlipTheme.upiGreen).frame(width: 5, height: 5)
                            Text("READY ON TURNSTILE")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(0.6)
                                .foregroundStyle(SlipTheme.upiGreen)
                        }
                        Text("MG Road → Whitefield")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(SlipTheme.ink)
                    }
                }
                Spacer()
                Image(systemName: "sensor.tag.radiowaves.forward")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SlipTheme.accentSoft)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(SlipTheme.accent.opacity(0.12)))
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.35))
            )

            HStack {
                Label("Auto-surfaces near AF Gate", systemImage: "lock.iphone")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SlipTheme.muted)
                Spacer()
                Text("Apple Wallet ›")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(SlipTheme.accentSoft)
            }
            .padding(.top, 2)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x251B3D), Color(hex: 0x120E2E)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.28), Color.white.opacity(0.04)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: .black.opacity(0.45), radius: 20, y: 12)
        }
    }

    private func previewGlass(corner: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Color.white.opacity(0.04))
            }
            .overlay {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
            }
    }

    // MARK: - Auth dock

    private var authDock: some View {
        VStack(spacing: 12) {
            SignInWithAppleButton(.continue) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                handleApple(result)
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 52)
            .clipShape(Capsule())
            .disabled(!auth.cloudStatus.isReady)
            .opacity(auth.cloudStatus.isReady ? 1 : 0.45)

            if let localError {
                Text(localError)
                    .font(.footnote)
                    .foregroundStyle(SlipTheme.magenta)
                    .multilineTextAlignment(.center)
            }

            trustSeal

            Text("By continuing, you acknowledge Slip's Transit Protocol terms. Works natively with Apple Wallet & PassKit frameworks. All trademarks belong to respective transit authorities.")
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.4)
                .foregroundStyle(SlipTheme.muted.opacity(0.55))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)
        }
    }

    private var trustSeal: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle().fill(SlipTheme.accent.opacity(0.18)).frame(width: 28, height: 28)
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SlipTheme.accentSoft)
            }
            (
                Text("Zero-Knowledge Architecture. ")
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
                + Text("Encrypted on Apple Neural Engine & stored directly in your iPhone's Secure Enclave.")
                    .foregroundStyle(SlipTheme.muted.opacity(0.9))
            )
            .font(.system(size: 10, weight: .medium))
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
    }

    // MARK: - Actions

    private func handleApple(_ result: Result<ASAuthorization, Error>) {
        localError = nil
        switch result {
        case .failure(let error):
            localError = error.localizedDescription
        case .success(let authResult):
            guard let credential = authResult.credential as? ASAuthorizationAppleIDCredential else {
                localError = "Unexpected Apple credential."
                return
            }
            auth.applyAppleCredential(
                userID: credential.user,
                fullName: credential.fullName,
                email: credential.email
            )
            Task { await model.bootstrap() }
        }
    }
}
