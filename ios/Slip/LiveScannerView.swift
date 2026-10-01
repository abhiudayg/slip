import AVFoundation
import Photos
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import Vision

/// Artboard — Live Camera Scanner (Stitch `live_scanner_slip_wallet_1`).
struct LiveScannerView: View {
    var onCode: (String, String) -> Void
    var onImage: (UIImage) -> Void
    var onPDF: ((Data) -> Void)? = nil
    var onCancel: () -> Void

    @State private var isTorchOn = false
    @State private var scanLineOffset: CGFloat = -130
    @State private var recentThumbs: [(id: String, image: UIImage)] = []
    @State private var photoAuthDenied = false
    @State private var photoItem: PhotosPickerItem?
    @State private var showFileImporter = false
    @State private var importError: String?

    var body: some View {
        ZStack {
            // Live Camera Background
            ScannerCameraRepresentable(onCode: onCode, isTorchOn: isTorchOn)
                .ignoresSafeArea()

            // Viewfinder Cutout Mask (darkening outside 280x280 box)
            GeometryReader { proxy in
                let size = proxy.size
                let boxSize: CGFloat = 280
                let topOffset = (size.height - boxSize) / 2
                let leftOffset = (size.width - boxSize) / 2

                ZStack {
                    // Top Mask
                    Color.black.opacity(0.65)
                        .frame(width: size.width, height: max(topOffset, 0))
                        .position(x: size.width / 2, y: topOffset / 2)

                    // Bottom Mask
                    Color.black.opacity(0.65)
                        .frame(width: size.width, height: max(topOffset, 0))
                        .position(x: size.width / 2, y: size.height - topOffset / 2)

                    // Left Mask
                    Color.black.opacity(0.65)
                        .frame(width: max(leftOffset, 0), height: boxSize)
                        .position(x: leftOffset / 2, y: size.height / 2)

                    // Right Mask
                    Color.black.opacity(0.65)
                        .frame(width: max(leftOffset, 0), height: boxSize)
                        .position(x: size.width - leftOffset / 2, y: size.height / 2)
                }
                .ignoresSafeArea()
            }

            // Central Scanning Frame / Viewfinder HUD
            viewfinderBox

            // Foreground UI Overlay (Top Bar, Helper, Bottom Actions)
            VStack(spacing: 0) {
                topHUD
                    .padding(.horizontal, 20)
                    .padding(.top, 14)

                Spacer()

                instructionPrompt
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                bottomActions
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                scanLineOffset = 130
            }
        }
        .task { await loadRecentPhotos() }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { @MainActor in
                defer { photoItem = nil }
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    onImage(image)
                }
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            guard let onPDF else { return }
            Task { @MainActor in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                    do {
                        onPDF(try Data(contentsOf: url))
                    } catch {
                        importError = error.localizedDescription
                    }
                case .failure(let error):
                    importError = error.localizedDescription
                }
            }
        }
        .alert("Couldn’t import PDF", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importError ?? "")
        }
    }

    // MARK: - Central Viewfinder Box

    private var viewfinderBox: some View {
        ZStack {
            // Viewfinder Border Container (16px corner radius, NOT pill)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                .frame(width: 280, height: 280)

            // Animated Emerald Laser Scan Beam
            Rectangle()
                .fill(SlipTheme.upiGreen)
                .frame(width: 276, height: 2.5)
                .shadow(color: SlipTheme.upiGreen.opacity(0.8), radius: 8, y: 0)
                .shadow(color: SlipTheme.upiGreen.opacity(0.4), radius: 16, y: 0)
                .offset(y: scanLineOffset)

            // HUD Targeting Corner Brackets (Exact 16px corner radius contour)
            cornerBrackets

            // Central Subtle Alignment Crosshair
            crosshair

            // HUD Metadata Marks inside Frame
            VStack {
                HStack {
                    Spacer()
                    Text("AUTO-FOCUS")
                        .font(SlipTheme.labelMono())
                        .foregroundStyle(SlipTheme.upiGreen.opacity(0.85))
                }
                Spacer()
                HStack {
                    Text("ISO-800 · 4K 60FPS")
                        .font(SlipTheme.labelMono())
                        .foregroundStyle(SlipTheme.upiGreen.opacity(0.85))
                    Spacer()
                }
            }
            .frame(width: 256, height: 256)
        }
    }

    private var cornerBrackets: some View {
        ZStack {
            // Top Left
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 0) {
                    bracketCorner
                        .rotationEffect(.degrees(0))
                    Spacer()
                    bracketCorner
                        .rotationEffect(.degrees(90))
                }
                Spacer()
                HStack(alignment: .bottom, spacing: 0) {
                    bracketCorner
                        .rotationEffect(.degrees(270))
                    Spacer()
                    bracketCorner
                        .rotationEffect(.degrees(180))
                }
            }
            .frame(width: 280, height: 280)
        }
    }

    private var bracketCorner: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 28))
            path.addLine(to: CGPoint(x: 0, y: 16))
            path.addQuadCurve(to: CGPoint(x: 16, y: 0), control: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 28, y: 0))
        }
        .stroke(SlipTheme.upiGreen, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
        .frame(width: 28, height: 28)
        .shadow(color: SlipTheme.upiGreen.opacity(0.8), radius: 4)
    }

    private var crosshair: some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.35))
                .frame(width: 28, height: 1)
            Rectangle()
                .fill(Color.white.opacity(0.35))
                .frame(width: 1, height: 28)
        }
    }

    // MARK: - Top HUD

    private var topHUD: some View {
        VStack(spacing: 10) {
            HStack {
                // Dismiss Button (14px rounded rectangle)
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(SlipTheme.ink)
                        .frame(width: 42, height: 42)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(SlipTheme.cardHigh.opacity(0.65))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)

                Spacer()

                // Status Capsule (10px rounded rectangle, NOT a pill)
                HStack(spacing: 8) {
                    Circle()
                        .fill(SlipTheme.upiGreen)
                        .frame(width: 7, height: 7)
                        .shadow(color: SlipTheme.upiGreen, radius: 4)
                    Text("SCANNING TICKET / PASS")
                        .font(SlipTheme.labelMono())
                        .tracking(0.8)
                        .foregroundStyle(SlipTheme.upiGreen)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(SlipTheme.canvasLowest.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(SlipTheme.upiGreen.opacity(0.35), lineWidth: 1)
                        )
                )

                Spacer()

                // Torch Toggle Button (14px rounded rectangle)
                Button {
                    isTorchOn.toggle()
                    SlipHaptics.scrollTick()
                } label: {
                    Image(systemName: isTorchOn ? "bolt.fill" : "bolt.slash.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isTorchOn ? Color.yellow : SlipTheme.ink)
                        .frame(width: 42, height: 42)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(SlipTheme.cardHigh.opacity(0.65))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
            }

            // PassKit AI OCR Active Banner (12px rounded rectangle)
            HStack(spacing: 6) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SlipTheme.upiGreen)
                Text("PassKit AI OCR Active")
                    .font(SlipTheme.labelMono())
                    .foregroundStyle(SlipTheme.ink)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(SlipTheme.cardHigh.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Instruction Prompt

    private var instructionPrompt: some View {
        Text("Position pass or boarding card within frame to automatically import into Slip")
            .font(SlipTheme.bodySM())
            .fontWeight(.medium)
            .foregroundStyle(SlipTheme.ink)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(SlipTheme.canvasLowest.opacity(0.75))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                    )
            )
    }

    // MARK: - Bottom Actions

    private var bottomActions: some View {
        VStack(spacing: 10) {
            // Recent photo strip if photos available
            if !recentThumbs.isEmpty {
                recentPhotoThumbStrip
            }

            // Import from Photos (16px rounded rectangle, NOT a pill)
            PhotosPicker(selection: $photoItem, matching: .images) {
                HStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Import from Photos")
                        .font(SlipTheme.headlineSM())
                        .fontWeight(.semibold)
                }
                .foregroundStyle(SlipTheme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(SlipTheme.cardHigh.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)

            // Split Actions: Enter Details Manually & Cancel
            HStack(spacing: 10) {
                Button {
                    // Manual entry
                    onCancel()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 15))
                            .foregroundStyle(SlipTheme.muted)
                        Text("Enter Details")
                            .font(SlipTheme.labelMono())
                            .foregroundStyle(SlipTheme.ink)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(SlipTheme.cardHigh.opacity(0.65))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)

                Button(action: onCancel) {
                    Text("Cancel")
                        .font(SlipTheme.bodyMD())
                        .fontWeight(.semibold)
                        .foregroundStyle(SlipTheme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(SlipTheme.cardHigh.opacity(0.65))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var recentPhotoThumbStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(recentThumbs.prefix(6), id: \.id) { item in
                    Button {
                        Task { await pickFullImage(assetId: item.id) }
                    } label: {
                        Image(uiImage: item.image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Photos Loading

    private func loadRecentPhotos() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard status == .authorized || status == .limited else {
            photoAuthDenied = true
            return
        }
        photoAuthDenied = false

        let thumbs: [(String, UIImage)] = await Task.detached(priority: .userInitiated) {
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            options.fetchLimit = 12
            let result = PHAsset.fetchAssets(with: .image, options: options)
            var out: [(String, UIImage)] = []
            let manager = PHImageManager.default()
            let requestOptions = PHImageRequestOptions()
            requestOptions.deliveryMode = .fastFormat
            requestOptions.resizeMode = .fast
            requestOptions.isSynchronous = true
            requestOptions.isNetworkAccessAllowed = true
            let target = CGSize(width: 120, height: 120)
            result.enumerateObjects { asset, _, stop in
                manager.requestImage(
                    for: asset,
                    targetSize: target,
                    contentMode: .aspectFill,
                    options: requestOptions
                ) { image, _ in
                    if let image { out.append((asset.localIdentifier, image)) }
                }
                if out.count >= 12 { stop.pointee = true }
            }
            return out
        }.value

        recentThumbs = thumbs.map { (id: $0.0, image: $0.1) }
    }

    private func pickFullImage(assetId: String) async {
        let image: UIImage? = await Task.detached(priority: .userInitiated) {
            let result = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
            guard let asset = result.firstObject else { return nil }
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = true
            options.isNetworkAccessAllowed = true
            var out: UIImage?
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .default,
                options: options
            ) { image, _ in
                out = image
            }
            return out
        }.value
        if let image {
            onImage(image)
        }
    }
}

// MARK: - Camera & Torch Representable

struct ScannerCameraRepresentable: UIViewControllerRepresentable {
    var onCode: (String, String) -> Void
    var isTorchOn: Bool = false

    func makeUIViewController(context: Context) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.onCode = onCode
        return vc
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        uiViewController.setTorch(on: isTorchOn)
    }
}

final class ScannerViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var onCode: ((String, String) -> Void)?
    private let session = AVCaptureSession()
    private var didEmit = false
    private let queue = DispatchQueue(label: "com.slip.scanner")
    private var videoDevice: AVCaptureDevice?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        videoDevice = device
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setTorch(on: false)
        session.stopRunning()
    }

    func setTorch(on: Bool) {
        guard let device = videoDevice, device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !didEmit,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let request = VNDetectBarcodesRequest { [weak self] request, _ in
            guard let self, !self.didEmit,
                  let results = request.results as? [VNBarcodeObservation],
                  let best = results.first,
                  let payload = best.payloadStringValue,
                  !payload.isEmpty else { return }
            self.didEmit = true
            let symbology = String(describing: best.symbology.rawValue)
            DispatchQueue.main.async {
                SlipHaptics.scanSuccess()
                self.onCode?(payload, symbology)
            }
        }
        request.symbologies = [.qr, .code128, .pdf417, .aztec, .ean13, .ean8]
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
}
