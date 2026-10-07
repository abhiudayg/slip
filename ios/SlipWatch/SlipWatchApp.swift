import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

@main
struct SlipWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchPassListView()
        }
    }
}

struct WatchPassListView: View {
    @State private var passes: [WidgetPassSnapshot] = []

    var body: some View {
        NavigationStack {
            List {
                if passes.isEmpty {
                    Text("Unlock Slip on iPhone to sync QR snapshots.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Section("Relevant now") {
                        ForEach(passes) { pass in
                            NavigationLink {
                                WatchQRDetailView(pass: pass)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(pass.displayName)
                                        .font(.headline)
                                    Text(pass.subtitle)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Slip")
            .onAppear(perform: reload)
            .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { _ in
                reload()
            }
        }
    }

    private func reload() {
        passes = WidgetPassStore.relevanceSorted()
    }
}

struct WatchQRDetailView: View {
    let pass: WidgetPassSnapshot

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text(pass.displayName)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Text(pass.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                WatchQRCodeView(payload: pass.qrPayload)
                    .frame(width: 140, height: 140)
                    .padding(8)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 10))
                Text(pass.qrPayload)
                    .font(.slipSystem(size: 9, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 8)
        }
        .navigationTitle("Scan")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WatchQRCodeView: View {
    let payload: String

    var body: some View {
        if let image = Self.makeImage(payload) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "qrcode")
                .resizable()
                .scaledToFit()
                .padding(20)
        }
    }

    private static func makeImage(_ payload: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}
