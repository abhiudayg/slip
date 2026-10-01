import PassKit
import SwiftUI

/// Lightweight invite surface — friend taps iMessage Universal Link → App Clip → Add to Wallet.
struct AppClipRootView: View {
    @EnvironmentObject private var model: AppClipModel

    var body: some View {
        ZStack {
            MeshBackground()
            VStack(spacing: 20) {
                Text("Slip")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(SlipTheme.ink)
                Text("Shared pass")
                    .font(.subheadline)
                    .foregroundStyle(SlipTheme.muted)

                if let package = model.package {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(package.displayName)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(SlipTheme.ink)
                        Text(package.templateId.uppercased())
                            .font(.caption.weight(.bold))
                            .foregroundStyle(SlipTheme.accentSoft)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )

                    if let passData = model.passData, PKAddPassesViewController.canAddPasses() {
                        AddToWalletButton(passData: passData) { _ in }
                    } else {
                        Button {
                            Task { await model.addToWallet() }
                        } label: {
                            HStack {
                                if model.isBuilding { ProgressView().tint(.black) }
                                Text(model.isBuilding ? "Building pass…" : "Add to Apple Wallet")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .foregroundStyle(.black)
                            .background(Capsule().fill(Color.white))
                        }
                        .disabled(model.isBuilding)
                        .buttonStyle(.plain)
                    }
                } else {
                    Text("Open a Slip share link from Messages to preview a ticket here.")
                        .font(.subheadline)
                        .foregroundStyle(SlipTheme.muted)
                        .multilineTextAlignment(.center)
                }

                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red.opacity(0.9))
                        .multilineTextAlignment(.center)
                }

                Spacer(minLength: 0)
            }
            .padding(24)
        }
    }
}
