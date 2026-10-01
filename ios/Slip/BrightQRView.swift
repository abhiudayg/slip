import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

/// Full-screen max-brightness QR — opened from home-screen widget / Watch handoff.
struct BrightQRView: View {
    let passId: String
    let displayName: String
    let payload: String
    var onDismiss: () -> Void

    @State private var priorBrightness: CGFloat?

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 28) {
                Text(displayName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                if let image = makeQR(payload) {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 280, maxHeight: 280)
                        .padding(16)
                        .background(Color.white)
                } else {
                    Image(systemName: "qrcode")
                        .font(.system(size: 120))
                        .foregroundStyle(.black)
                }
                Text(payload)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.black.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Button("Done") { onDismiss() }
                    .font(.headline)
                    .padding(.top, 8)
            }
            .padding()
        }
        .onAppear {
            priorBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1.0
            UIApplication.shared.isIdleTimerDisabled = true
            SlipHaptics.brightQRReady()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            if let priorBrightness {
                UIScreen.main.brightness = priorBrightness
            }
        }
        .statusBarHidden(true)
    }

    private func makeQR(_ payload: String) -> UIImage? {
        #if canImport(CoreImage)
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        let context = CIContext()
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
        #else
        return nil
        #endif
    }
}
