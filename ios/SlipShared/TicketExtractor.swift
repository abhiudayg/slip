import Foundation
import UIKit
import Vision
import PDFKit

enum TicketExtractor {
    struct BarcodeHit: Sendable {
        let message: String
        let symbology: String
    }

    /// Full screenshot / photo pipeline: barcodes + OCR text.
    static func extract(from image: UIImage) async -> ExtractedTicket {
        guard let cgImage = normalizedCGImage(from: image) else {
            return emptyTicket()
        }
        async let barcode = detectBarcode(in: cgImage)
        async let text = recognizeText(in: cgImage)
        let hit = await barcode
        let ocr = await text
        return makeTicket(qr: hit?.message, symbology: hit?.symbology, text: ocr)
    }

    /// Booking / ticket PDF: embedded text + rendered pages for QR/barcodes + OCR fallback.
    static func extract(fromPDF data: Data) async -> ExtractedTicket {
        guard let document = PDFDocument(data: data), document.pageCount > 0 else {
            return emptyTicket()
        }

        var textChunks: [String] = []
        var hit: BarcodeHit?
        let pageLimit = min(document.pageCount, 6)

        for index in 0..<pageLimit {
            guard let page = document.page(at: index) else { continue }
            if let pageText = page.string?.trimmingCharacters(in: .whitespacesAndNewlines), !pageText.isEmpty {
                textChunks.append(pageText)
            }

            guard let rendered = render(page: page, scale: 2.5),
                  let cgImage = rendered.cgImage else { continue }

            if hit == nil {
                hit = await detectBarcode(in: cgImage)
            }

            // OCR when PDF has little selectable text (scanned ticket PDFs).
            let embeddedLen = page.string?.count ?? 0
            if embeddedLen < 40 {
                let ocr = await recognizeText(in: cgImage)
                if !ocr.isEmpty { textChunks.append(ocr) }
            }
        }

        var combined = textChunks.joined(separator: "\n")
        if combined.count < 40, let page = document.page(at: 0),
           let rendered = render(page: page, scale: 2.5),
           let cgImage = rendered.cgImage {
            let ocr = await recognizeText(in: cgImage)
            if !ocr.isEmpty {
                combined = [combined, ocr].filter { !$0.isEmpty }.joined(separator: "\n")
            }
        }

        return makeTicket(qr: hit?.message, symbology: hit?.symbology, text: combined)
    }

    /// Fast path when we already have a barcode payload (live scanner).
    static func extract(payload: String, symbology: String, surroundingText: String = "") -> ExtractedTicket {
        makeTicket(qr: payload, symbology: symbology, text: surroundingText)
    }

    static func detectBarcode(in cgImage: CGImage) async -> BarcodeHit? {
        await withCheckedContinuation { continuation in
            let request = VNDetectBarcodesRequest { request, _ in
                let results = (request.results as? [VNBarcodeObservation]) ?? []
                let withPayload = results.filter { $0.payloadStringValue != nil }
                let preferred =
                    withPayload.first(where: { $0.symbology == .qr })
                    ?? withPayload.first(where: { $0.symbology == .pdf417 })
                    ?? withPayload.first(where: { $0.symbology == .aztec })
                    ?? withPayload.first(where: { $0.symbology == .code128 })
                    ?? withPayload.first

                guard let preferred, let payload = preferred.payloadStringValue else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: BarcodeHit(
                    message: payload,
                    symbology: String(describing: preferred.symbology.rawValue)
                ))
            }
            request.symbologies = [.qr, .code128, .pdf417, .aztec, .ean13, .ean8, .dataMatrix]
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }

    static func recognizeText(in cgImage: CGImage) async -> String {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-IN", "en-US", "hi-IN"]
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: "")
            }
        }
    }

    private static func makeTicket(qr: String?, symbology: String?, text: String) -> ExtractedTicket {
        let trimmedQR = qr?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let joined = [trimmedQR, cleanedText].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: "\n")
        return ExtractedTicket(
            qrPayload: (trimmedQR?.isEmpty == false) ? trimmedQR : nil,
            barcodeSymbology: symbology,
            recognizedText: cleanedText,
            tokens: tokenize(joined),
            createdAt: Date()
        )
    }

    private static func emptyTicket() -> ExtractedTicket {
        ExtractedTicket(
            qrPayload: nil,
            barcodeSymbology: nil,
            recognizedText: "",
            tokens: [],
            createdAt: Date()
        )
    }

    /// Flatten EXIF orientation so Vision sees upright pixels (common share/screenshot failure).
    private static func normalizedCGImage(from image: UIImage) -> CGImage? {
        if image.imageOrientation == .up, let cg = image.cgImage {
            return cg
        }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = image.scale
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        let drawn = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        return drawn.cgImage
    }

    private static func render(page: PDFPage, scale: CGFloat) -> UIImage? {
        let bounds = page.bounds(for: .mediaBox)
        guard bounds.width > 1, bounds.height > 1 else { return nil }
        let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            ctx.cgContext.saveGState()
            ctx.cgContext.translateBy(x: 0, y: size.height)
            ctx.cgContext.scaleBy(x: scale, y: -scale)
            page.draw(with: .mediaBox, to: ctx.cgContext)
            ctx.cgContext.restoreGState()
        }
    }

    private static func tokenize(_ text: String) -> [String] {
        text
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 2 }
    }
}
