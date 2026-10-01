import AuthenticationServices
import SwiftUI

/// Launch screen matching Stitch `login_slip_wallet`.
struct LoginView: View {
    @EnvironmentObject private var auth: AuthSession
    @EnvironmentObject private var model: AppModel
    @State private var localError: String?

    private let margin: CGFloat = 24

    var body: some View {
        ZStack {
            MeshBackground(holographicMotif: true)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 8)

                    brandHeader
                        .frame(maxWidth: .infinity)

                    passStackPreview
                        .padding(.top, 24)
                        .frame(maxWidth: .infinity)

                    Spacer(minLength: 20)

                    authDock
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 16)
                }
                .padding(.horizontal, margin)
                .frame(maxWidth: .infinity)
                .containerRelativeFrame(.vertical, alignment: .center)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await auth.refreshCloud(using: model.api)
        }
    }

    // MARK: - Brand

    private var brandHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(SlipTheme.tertiary)
                Text("PASSKIT VAULT 2.0")
                    .font(SlipTheme.labelMono())
                    .tracking(1.2)
                    .foregroundStyle(SlipTheme.inkVariant)
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(SlipTheme.upiGreen.opacity(0.85))
                    .frame(width: 6, height: 6)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(SlipTheme.cardHigh.opacity(0.60))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                    )
            )
            .padding(.bottom, 28)

            SlipBrandMark(size: 96, glow: true)
                .frame(width: 96, height: 96)
                .padding(.bottom, 20)

            // Optical center: trailing square-dot sits in overlay so "Slip" stays centered.
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("Slip")
                    .font(SlipTheme.headlineXL())
                    .tracking(-0.8)
                    .foregroundStyle(SlipTheme.ink)
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(SlipTheme.tertiaryDim)
                    .frame(width: 6, height: 6)
                    .padding(.bottom, 6)
            }

            Text("The digital slip & passkit vault. All your boarding passes, keys & cards in one secure place.")
                .font(SlipTheme.bodyMD())
                .foregroundStyle(SlipTheme.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 320)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Glass bento micro-preview

    private var passStackPreview: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                microPassCard(
                    icon: "airplane.departure",
                    meta: "GATE 24",
                    title: "JFK → HND",
                    subtitle: "Priority Boarding"
                )
                microPassCard(
                    icon: "key.fill",
                    meta: "ROOM 804",
                    title: "The Edition",
                    subtitle: "NFC Key Ready"
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func microPassCard(
        icon: String,
        meta: String,
        title: String,
        subtitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SlipTheme.tertiary)
                Spacer(minLength: 0)
                Text(meta)
                    .font(SlipTheme.labelMono())
                    .tracking(0.5)
                    .foregroundStyle(SlipTheme.muted)
                    .lineLimit(1)
            }
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SlipTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Text(subtitle)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(SlipTheme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(SlipTheme.cardHigh.opacity(0.40))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                )
        )
        .gridCellColumns(1)
    }

    // MARK: - Auth dock

    private var authDock: some View {
        VStack(spacing: 14) {
#if targetEnvironment(simulator)
            Button {
                auth.signInForSimulatorTesting()
                Task { await model.bootstrap() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Sign in with Apple")
                        .font(SlipTheme.headlineSM())
                }
                .foregroundStyle(SlipTheme.canvasDeep)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(SlipTheme.ink)
                        .shadow(color: .black.opacity(0.40), radius: 12, y: 8)
                )
            }
            .buttonStyle(.plain)

            Text("Simulator — continues without an Apple ID")
                .font(SlipTheme.labelMono())
                .foregroundStyle(SlipTheme.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
#else
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                handleApple(result)
            }
            .signInWithAppleButtonStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.40), radius: 12, y: 8)
            .disabled(!auth.cloudStatus.isReady)
            .opacity(auth.cloudStatus.isReady ? 1 : 0.45)
#endif

            if let localError {
                Text(localError)
                    .font(SlipTheme.bodySM())
                    .foregroundStyle(Color(hex: 0xFFB4AB))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            VStack(spacing: 6) {
                Text("By continuing, you agree to Slip's Terms & Privacy Policy.")
                    .font(SlipTheme.labelMono())
                    .foregroundStyle(SlipTheme.outline)
                    .multilineTextAlignment(.center)

                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Protected by Secure Enclave & VAS 2.0")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                }
                .foregroundStyle(SlipTheme.outlineVariant)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
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
