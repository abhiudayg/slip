import PassKit
import SwiftUI

/// Presents Apple's Add Passes sheet when the .pkpass is valid & signed.
/// Unsigned / invalid packs stay on-screen with an error (no navigation).
struct AddToWalletButton: View {
    let passData: Data
    /// Called only after the pass is actually present in PassKit.
    var onAdded: (PKPass) -> Void = { _ in }

    @State private var errorMessage: String?
    @State private var controller: PKAddPassesViewController?
    @State private var pendingPass: PKPass?

    var body: some View {
        VStack(spacing: 12) {
            if PKAddPassesViewController.canAddPasses() {
                Button {
                    present()
                } label: {
                    Label("Add to Apple Wallet", systemImage: "wallet.pass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("This device cannot add passes to Apple Wallet.")
                    .foregroundStyle(.secondary)
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .background(
            Group {
                if let controller {
                    AddPassesRepresentable(
                        controller: controller,
                        pendingPass: pendingPass
                    ) { added, pass in
                        self.controller = nil
                        self.pendingPass = nil
                        if added, let pass {
                            onAdded(pass)
                        }
                    }
                    .frame(width: 0, height: 0)
                }
            }
        )
    }

    private func present() {
        errorMessage = nil
        do {
            let pass = try PKPass(data: passData)
            if PKPassLibrary().containsPass(pass) {
                onAdded(pass)
                return
            }
            guard PKAddPassesViewController.canAddPasses() else {
                errorMessage = "This device cannot add passes to Apple Wallet."
                return
            }
            guard let vc = PKAddPassesViewController(pass: pass) else {
                errorMessage = "Could not open Add to Wallet."
                return
            }
            pendingPass = pass
            controller = vc
        } catch {
            errorMessage = """
            Apple Wallet rejected this file because it isn’t a valid signed pass.

            Generate again after pass-engine has a Pass Type ID certificate + WWDR configured.
            """
        }
    }
}

private struct AddPassesRepresentable: UIViewControllerRepresentable {
    let controller: PKAddPassesViewController
    let pendingPass: PKPass?
    var onFinish: (_ added: Bool, _ pass: PKPass?) -> Void

    func makeUIViewController(context: Context) -> Host {
        let host = Host()
        host.onAppear = {
            controller.delegate = context.coordinator
            host.present(controller, animated: true)
        }
        return host
    }

    func updateUIViewController(_ uiViewController: Host, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(pendingPass: pendingPass, onFinish: onFinish)
    }

    final class Host: UIViewController {
        var onAppear: (() -> Void)?
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            onAppear?()
            onAppear = nil
        }
    }

    final class Coordinator: NSObject, PKAddPassesViewControllerDelegate {
        let pendingPass: PKPass?
        let onFinish: (Bool, PKPass?) -> Void

        init(pendingPass: PKPass?, onFinish: @escaping (Bool, PKPass?) -> Void) {
            self.pendingPass = pendingPass
            self.onFinish = onFinish
        }

        func addPassesViewControllerDidFinish(_ controller: PKAddPassesViewController) {
            let added: Bool
            if let pendingPass {
                added = PKPassLibrary().containsPass(pendingPass)
            } else {
                added = false
            }
            controller.dismiss(animated: true) {
                self.onFinish(added, self.pendingPass)
            }
        }
    }
}
