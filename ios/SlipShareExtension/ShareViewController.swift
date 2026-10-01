import UIKit
import UniformTypeIdentifiers

@objc(ShareViewController)
class ShareViewController: UIViewController {
    private let spinner = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        spinner.color = .white
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        spinner.startAnimating()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Task { await processIncoming() }
    }

    private func processIncoming() async {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let provider = item.attachments?.first else {
            finish()
            return
        }

        do {
            let extracted: ExtractedTicket
            if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                let data = try await loadData(from: provider, typeIdentifier: UTType.pdf.identifier)
                extracted = await TicketExtractor.extract(fromPDF: data)
            } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                let image = try await loadImage(from: provider)
                extracted = await TicketExtractor.extract(from: image)
            } else if provider.hasItemConformingToTypeIdentifier("com.adobe.pdf") {
                let data = try await loadData(from: provider, typeIdentifier: "com.adobe.pdf")
                extracted = await TicketExtractor.extract(fromPDF: data)
            } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier)
                        || provider.hasItemConformingToTypeIdentifier("public.utf8-plain-text")
                        || provider.hasItemConformingToTypeIdentifier("public.text") {
                let typeId = provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier)
                    ? UTType.plainText.identifier
                    : (provider.hasItemConformingToTypeIdentifier("public.utf8-plain-text")
                       ? "public.utf8-plain-text" : "public.text")
                let text = try await loadString(from: provider, typeIdentifier: typeId)
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmed.count >= 24 else {
                    presentAlert("That text doesn’t look like a booking confirmation.")
                    return
                }
                extracted = TicketExtractor.extract(
                    payload: "",
                    symbology: "none",
                    surroundingText: trimmed
                )
            } else {
                presentAlert("Share a ticket PDF, screenshot, or booking email text with Slip.")
                return
            }

            let hasSignal = extracted.qrPayload != nil
                || extracted.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 12
            guard hasSignal else {
                presentAlert("Couldn’t read a QR or booking text from that file.")
                return
            }

            let classification = await IntelligentBrandClassifier.classify(extracted)
            SharedInbox.save(classification)
            openHostApp()
            finish()
        } catch {
            presentAlert(error.localizedDescription)
        }
    }


    private func loadString(from provider: NSItemProvider, typeIdentifier: String) async throws -> String {
        if provider.canLoadObject(ofClass: NSString.self) {
            let object: NSString = try await withCheckedThrowingContinuation { continuation in
                _ = provider.loadObject(ofClass: NSString.self) { object, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let value = object as? NSString {
                        continuation.resume(returning: value)
                    } else {
                        continuation.resume(throwing: NSError(domain: "SlipShare", code: 3, userInfo: [
                            NSLocalizedDescriptionKey: "Couldn’t read the shared text."
                        ]))
                    }
                }
            }
            return object as String
        }
        if provider.canLoadObject(ofClass: NSURL.self) {
            let nsurl: NSURL = try await withCheckedThrowingContinuation { continuation in
                _ = provider.loadObject(ofClass: NSURL.self) { object, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let value = object as? NSURL {
                        continuation.resume(returning: value)
                    } else {
                        continuation.resume(throwing: NSError(domain: "SlipShare", code: 3, userInfo: [
                            NSLocalizedDescriptionKey: "Couldn’t read the shared text."
                        ]))
                    }
                }
            }
            let url = nsurl as URL
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            return try String(contentsOf: url, encoding: .utf8)
        }
        let data = try await loadData(from: provider, typeIdentifier: typeIdentifier)
        if let s = String(data: data, encoding: .utf8) { return s }
        throw NSError(domain: "SlipShare", code: 3, userInfo: [
            NSLocalizedDescriptionKey: "Couldn’t read the shared text."
        ])
    }

    private func loadData(from provider: NSItemProvider, typeIdentifier: String) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            _ = provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: NSError(domain: "SlipShare", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: "Couldn’t read the shared PDF."
                    ]))
                }
            }
        }
    }

    private func loadImage(from provider: NSItemProvider) async throws -> UIImage {
        if provider.canLoadObject(ofClass: UIImage.self) {
            return try await withCheckedThrowingContinuation { continuation in
                _ = provider.loadObject(ofClass: UIImage.self) { object, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let image = object as? UIImage {
                        continuation.resume(returning: image)
                    } else {
                        continuation.resume(throwing: NSError(domain: "SlipShare", code: 2, userInfo: [
                            NSLocalizedDescriptionKey: "Couldn’t read the shared image."
                        ]))
                    }
                }
            }
        }
        let data = try await loadData(from: provider, typeIdentifier: UTType.image.identifier)
        if let image = UIImage(data: data) { return image }
        throw NSError(domain: "SlipShare", code: 2, userInfo: [
            NSLocalizedDescriptionKey: "Couldn’t read the shared image."
        ])
    }

    /// Private ObjC surface so we can use `#selector` instead of `Selector("openURL:")`.
    @objc private protocol OpenURLAction {
        func openURL(_ url: URL)
    }

    private func openHostApp() {
        guard let url = URL(string: "slip://shared") else { return }
        let openSel = #selector(OpenURLAction.openURL(_:))
        var responder: UIResponder? = self
        while let current = responder {
            if current.responds(to: openSel) {
                current.perform(openSel, with: url)
                return
            }
            responder = current.next
        }
    }

    private func presentAlert(_ message: String) {
        spinner.stopAnimating()
        let alert = UIAlertController(title: "Slip", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in self?.finish() })
        present(alert, animated: true)
    }

    private func finish() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
