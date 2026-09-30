import AVFoundation
import SwiftUI
import Vision

struct LiveScannerView: View {
    var onCode: (String, String) -> Void
    var onCancel: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScannerCameraRepresentable(onCode: onCode)
                .ignoresSafeArea()
            Button("Cancel", action: onCancel)
                .padding()
                .background(.ultraThinMaterial, in: Capsule())
                .padding()
            VStack {
                Spacer()
                Text("Point at a QR, Code128, or PDF417")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 40)
            }
        }
    }
}

struct ScannerCameraRepresentable: UIViewControllerRepresentable {
    var onCode: (String, String) -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.onCode = onCode
        return vc
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

final class ScannerViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var onCode: ((String, String) -> Void)?
    private let session = AVCaptureSession()
    private var didEmit = false
    private let queue = DispatchQueue(label: "com.slip.scanner")

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        session.beginConfiguration()
        if session.canAddInput(input) { session.addInput(input) }
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: queue)
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.layer.sublayers?.compactMap { $0 as? AVCaptureVideoPreviewLayer }.forEach {
            $0.frame = view.bounds
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !didEmit,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let request = VNDetectBarcodesRequest { [weak self] request, _ in
            guard let self, !self.didEmit,
                  let results = request.results as? [VNBarcodeObservation],
                  let hit = results.first,
                  let payload = hit.payloadStringValue else { return }
            self.didEmit = true
            let symbology = String(describing: hit.symbology.rawValue)
            DispatchQueue.main.async {
                self.session.stopRunning()
                self.onCode?(payload, symbology)
            }
        }
        request.symbologies = [.qr, .code128, .pdf417, .aztec, .ean13, .ean8]
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        try? handler.perform([request])
    }
}
