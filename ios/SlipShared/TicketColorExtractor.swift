import CoreGraphics
import UIKit

#if canImport(SwiftUI)
import SwiftUI
#endif

/// Samples ticket screenshot / PDF page thumbnails into a dominant palette (no third-party deps).
enum TicketColorExtractor {
    struct Swatch: Sendable {
        var dominant: (r: Double, g: Double, b: Double)
        var secondary: (r: Double, g: Double, b: Double)
        var accent: (r: Double, g: Double, b: Double)
    }

    private static let cacheKey = "slip.ticket.colorSwatch"

    static func cacheLast(_ swatch: Swatch) {
        let dict: [String: Double] = [
            "dr": swatch.dominant.r, "dg": swatch.dominant.g, "db": swatch.dominant.b,
            "sr": swatch.secondary.r, "sg": swatch.secondary.g, "sb": swatch.secondary.b,
            "ar": swatch.accent.r, "ag": swatch.accent.g, "ab": swatch.accent.b
        ]
        UserDefaults.standard.set(dict, forKey: cacheKey)
        UserDefaults(suiteName: SharedInbox.appGroupId)?.set(dict, forKey: cacheKey)
    }

    static func cachedSwatch() -> Swatch? {
        guard let dict = UserDefaults.standard.dictionary(forKey: cacheKey) as? [String: Double],
              let dr = dict["dr"], let dg = dict["dg"], let db = dict["db"],
              let sr = dict["sr"], let sg = dict["sg"], let sb = dict["sb"],
              let ar = dict["ar"], let ag = dict["ag"], let ab = dict["ab"] else { return nil }
        return Swatch(dominant: (dr, dg, db), secondary: (sr, sg, sb), accent: (ar, ag, ab))
    }

    static func extract(from image: UIImage, maxDimension: CGFloat = 64) -> Swatch? {
        guard let cg = resized(image, maxDimension: maxDimension) else { return nil }
        guard let data = cg.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return nil }

        let w = cg.width
        let h = cg.height
        let bytesPerPixel = max(cg.bitsPerPixel / 8, 4)
        let bytesPerRow = cg.bytesPerRow

        var buckets: [UInt32: (count: Int, r: Int, g: Int, b: Int)] = [:]
        buckets.reserveCapacity(64)

        // Sparse sample for speed.
        let step = max(1, min(w, h) / 24)
        for y in stride(from: 0, to: h, by: step) {
            for x in stride(from: 0, to: w, by: step) {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let b = Int(ptr[offset])
                let g = Int(ptr[offset + 1])
                let r = Int(ptr[offset + 2])
                // Skip near-white / near-black OCR noise.
                let lum = 0.2126 * Double(r) + 0.7152 * Double(g) + 0.0722 * Double(b)
                if lum < 18 || lum > 245 { continue }
                let key = quantize(r, g, b)
                var entry = buckets[key] ?? (0, 0, 0, 0)
                entry.count += 1
                entry.r += r
                entry.g += g
                entry.b += b
                buckets[key] = entry
            }
        }
        guard !buckets.isEmpty else { return nil }

        let ranked = buckets.values.sorted { $0.count > $1.count }
        func avg(_ e: (count: Int, r: Int, g: Int, b: Int)) -> (Double, Double, Double) {
            let c = Double(max(e.count, 1))
            return (Double(e.r) / c / 255, Double(e.g) / c / 255, Double(e.b) / c / 255)
        }
        let dominant = avg(ranked[0])
        let secondary = ranked.count > 1 ? avg(ranked[1]) : darken(dominant, 0.75)
        let accent = ranked.first(where: { sat(avg($0)) > 0.28 }).map(avg) ?? boost(dominant)

        return Swatch(dominant: dominant, secondary: secondary, accent: accent)
    }

    private static func quantize(_ r: Int, _ g: Int, _ b: Int) -> UInt32 {
        let rq = UInt32(r / 32)
        let gq = UInt32(g / 32)
        let bq = UInt32(b / 32)
        return (rq << 10) | (gq << 5) | bq
    }

    private static func sat(_ c: (Double, Double, Double)) -> Double {
        let mx = max(c.0, c.1, c.2)
        let mn = min(c.0, c.1, c.2)
        return mx <= 0 ? 0 : (mx - mn) / mx
    }

    private static func darken(_ c: (Double, Double, Double), _ f: Double) -> (Double, Double, Double) {
        (c.0 * f, c.1 * f, c.2 * f)
    }

    private static func boost(_ c: (Double, Double, Double)) -> (Double, Double, Double) {
        (min(1, c.0 * 1.35 + 0.08), min(1, c.1 * 1.25 + 0.05), min(1, c.2 * 1.2 + 0.05))
    }

    private static func resized(_ image: UIImage, maxDimension: CGFloat) -> CGImage? {
        let size = image.size
        let scale = min(1, maxDimension / max(size.width, size.height))
        let target = CGSize(width: max(1, size.width * scale), height: max(1, size.height * scale))
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let rendered = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return rendered.cgImage
    }
}
