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
        let items = extensionContext?.inputItems.compactMap { $0 as? NSExtensionItem } ?? []
        guard !items.isEmpty else {
            finish()
            return
        }

        do {
            // Prefer attributed email body Mail puts on the extension item itself.
            for item in items {
                if let body = item.attributedContentText?.string
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                   body.count >= 24 {
                    try await classifyAndHandoff(text: body)
                    return
                }
            }

            let providers = items.flatMap { $0.attachments ?? [] }
            guard !providers.isEmpty else {
                presentAlert("Share a ticket PDF, screenshot, or booking email with Slip.")
                return
            }

            // Try richest booking signal first: PDF → image → HTML → plain text → URL file.
            if let provider = providers.first(where: {
                $0.hasItemConformingToTypeIdentifier(UTType.pdf.identifier)
                    || $0.hasItemConformingToTypeIdentifier("com.adobe.pdf")
            }) {
                let typeId = provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier)
                    ? UTType.pdf.identifier : "com.adobe.pdf"
                let data = try await loadData(from: provider, typeIdentifier: typeId)
                let extracted = await TicketExtractor.extract(fromPDF: data)
                try await classifyAndHandoff(extracted: extracted)
                return
            }

            if let provider = providers.first(where: {
                $0.hasItemConformingToTypeIdentifier(UTType.image.identifier)
            }) {
                let image = try await loadImage(from: provider)
                let extracted = await TicketExtractor.extract(from: image)
                try await classifyAndHandoff(extracted: extracted)
                return
            }

            if let provider = providers.first(where: {
                $0.hasItemConformingToTypeIdentifier(UTType.html.identifier)
                    || $0.hasItemConformingToTypeIdentifier("public.html")
            }) {
                let typeId = provider.hasItemConformingToTypeIdentifier(UTType.html.identifier)
                    ? UTType.html.identifier : "public.html"
                let html = try await loadString(from: provider, typeIdentifier: typeId)
                let text = Self.plainText(fromHTML: html)
                guard text.count >= 24 else {
                    presentAlert("That email doesn’t look like a booking confirmation.")
                    return
                }
                try await classifyAndHandoff(text: text)
                return
            }

            if let provider = providers.first(where: {
                $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier)
                    || $0.hasItemConformingToTypeIdentifier("public.utf8-plain-text")
                    || $0.hasItemConformingToTypeIdentifier("public.text")
            }) {
                let typeId: String
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    typeId = UTType.plainText.identifier
                } else if provider.hasItemConformingToTypeIdentifier("public.utf8-plain-text") {
                    typeId = "public.utf8-plain-text"
                } else {
                    typeId = "public.text"
                }
                let text = try await loadString(from: provider, typeIdentifier: typeId)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                guard text.count >= 24 else {
                    presentAlert("That text doesn’t look like a booking confirmation.")
                    return
                }
                try await classifyAndHandoff(text: text)
                return
            }

            if let provider = providers.first(where: {
                $0.hasItemConformingToTypeIdentifier(UTType.url.identifier)
                    || $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
            }) {
                let typeId = provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
                    ? UTType.fileURL.identifier : UTType.url.identifier
                let text = try await loadString(from: provider, typeIdentifier: typeId)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if text.count >= 24 {
                    try await classifyAndHandoff(text: text)
                    return
                }
            }

            presentAlert("Share a ticket PDF, screenshot, or booking email text with Slip.")
        } catch {
            presentAlert(error.localizedDescription)
        }
    }

    private func classifyAndHandoff(text: String) async throws {
        let extracted = TicketExtractor.extract(
            payload: "",
            symbology: "none",
            surroundingText: text
        )
        try await classifyAndHandoff(extracted: extracted)
    }

    private func classifyAndHandoff(extracted: ExtractedTicket) async throws {
        let hasSignal = extracted.qrPayload != nil
            || extracted.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 12
        guard hasSignal else {
            presentAlert("Couldn’t read a QR or booking text from that share.")
            return
        }

        let classification = await IntelligentBrandClassifier.classify(extracted)
        SharedInbox.save(classification)
        openHostApp()
        finish()
    }

    /// Naive HTML → text so Mail HTML bodies still feed TicketExtractor.
    private static func plainText(fromHTML html: String) -> String {
        var s = html
        s = s.replacingOccurrences(of: #"(?is)<(script|style)[^>]*>.*?</\1>"#, with: " ", options: .regularExpression)
        s = s.replacingOccurrences(of: #"(?i)<br\s*/?>"#, with: "\n", options: .regularExpression)
        s = s.replacingOccurrences(of: #"(?i)</p>"#, with: "\n", options: .regularExpression)
        s = s.replacingOccurrences(of: #"(?i)</div>"#, with: "\n", options: .regularExpression)
        s = s.replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression)
        s = s
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
        return s
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
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
