import PassKit
import SwiftUI
import UniformTypeIdentifiers

/// Safer Add-to-Wallet presenter that surfaces PassKit errors instead of crashing on unsigned packs.
struct AddToWalletButton: View {
    let passData: Data
    var onAdded: () -> Void

    @State private var errorMessage: String?
    @State private var controller: PKAddPassesViewController?

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
                Text("This device cannot add passes.")
                    .foregroundStyle(.secondary)
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .background(
            Group {
                if let controller {
                    AddPassesRepresentable(controller: controller) {
                        self.controller = nil
                        onAdded()
                    }
                    .frame(width: 0, height: 0)
                }
            }
        )
    }

    private func present() {
        do {
            let pass = try PKPass(data: passData)
            guard let vc = PKAddPassesViewController(pass: pass) else {
                errorMessage = "Could not open Add to Wallet."
                return
            }
            controller = vc
        } catch {
            errorMessage = "PassKit rejected this file. In dev mode the engine ships unsigned packs — configure Apple signing certs on the server for a real Add."
        }
    }
}

private struct AddPassesRepresentable: UIViewControllerRepresentable {
    let controller: PKAddPassesViewController
    var onFinish: () -> Void

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
        Coordinator(onFinish: onFinish)
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
        let onFinish: () -> Void
        init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
        func addPassesViewControllerDidFinish(_ controller: PKAddPassesViewController) {
            controller.dismiss(animated: true) { self.onFinish() }
        }
    }
}
