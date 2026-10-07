import AVFoundation
import Photos
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import Vision

/// Artboard — Live Camera Scanner (Stitch `live_scanner_slip_wallet_1` & `live_scanner_slip_wallet_2`).
struct LiveScannerView: View {
    var onCode: (String, String) -> Void
    var onImage: (UIImage) -> Void
    var onPDF: ((Data) -> Void)? = nil
    var onManualEntry: (() -> Void)? = nil
    var onCancel: () -> Void

    @State private var isTorchOn = false
    @State private var scanLineOffset: CGFloat = -120
    @State private var isPulsing = false
    @State private var recentThumbs: [(id: String, image: UIImage)] = []
    @State private var photoAuthDenied = false
    @State private var photoItem: PhotosPickerItem?
    @State private var showFileImporter = false
    @State private var importError: String?

    var body: some View {
        ZStack {
            // Camera Feed (Live AVFoundation on hardware, realistic interactive feed on Simulator)
            #if targetEnvironment(simulator)
            SimulatedCameraFeedView {
                onCode("INDIGO|6E204|DEL-BLR|14A|SEAT|ALEX", "org.iso.PDF417")
            }
            .ignoresSafeArea()
            #else
            ScannerCameraRepresentable(onCode: onCode, isTorchOn: isTorchOn)
                .ignoresSafeArea()
            #endif

            // Cutout Mask: darkens the screen outside the 280x280 viewfinder box
            Color.black.opacity(0.65)
                .mask {
                    Rectangle()
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .frame(width: 280, height: 280)
                                .blendMode(.destinationOut)
                        }
                        .compositingGroup()
                }
                .ignoresSafeArea()

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
                    .padding(.bottom, 18)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                scanLineOffset = 120
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isPulsing = true
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

    // MARK: - Central Viewfinder Box (280x280, 16px corner radius)

    private var viewfinderBox: some View {
        ZStack {
            // Viewfinder Border Container (16px corner radius, NOT pill)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.20), lineWidth: 1)
                .frame(width: 280, height: 280)

            // Animated Emerald Laser Scan Beam with Flare
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [SlipTheme.upiGreen.opacity(0.20), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: 276, height: 36)

                Rectangle()
                    .fill(SlipTheme.upiGreen)
                    .frame(width: 276, height: 2.5)
                    .shadow(color: SlipTheme.upiGreen.opacity(0.85), radius: 8, y: 0)
                    .shadow(color: SlipTheme.upiGreen.opacity(0.40), radius: 16, y: 0)
            }
            .offset(y: scanLineOffset)
            .clipped()

            // Precision HUD Targeting Corner Brackets (Exact 16px corner radius contour)
            ViewfinderCornerBrackets(cornerRadius: 16, bracketLength: 28)
                .stroke(SlipTheme.upiGreen, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .frame(width: 280, height: 280)
                .shadow(color: SlipTheme.upiGreen.opacity(0.85), radius: 6)

            // Central Subtle Alignment Crosshair
            crosshair

            // HUD Metadata Marks inside Frame
            VStack {
                HStack {
                    Spacer()
                    Text("AUTO-FOCUS")
                        .font(SlipTheme.labelMono(10, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(SlipTheme.upiGreen.opacity(0.90))
                }
                Spacer()
                HStack(alignment: .bottom) {
                    Text("ISO-800 · 4K 60FPS")
                        .font(SlipTheme.labelMono(10, weight: .semibold))
                        .tracking(1.0)
                        .foregroundStyle(SlipTheme.upiGreen.opacity(0.90))

                    Spacer()

                    // Live Detection Badge (Stitch 2)
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.slipSystem(size: 9))
                            .foregroundStyle(SlipTheme.upiGreen)
                        Text("BCBP / QR")
                            .font(SlipTheme.labelMono(9, weight: .semibold))
                            .tracking(0.5)
                            .foregroundStyle(Color.white.opacity(0.85))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.black.opacity(0.65))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
                            )
                    )
                }
            }
            .frame(width: 254, height: 254)
        }
        .frame(width: 280, height: 280)
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
                        .font(.slipSystem(size: 15, weight: .semibold))
                        .foregroundStyle(SlipTheme.ink)
                        .frame(width: 44, height: 44)
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

                // Auto-Detect Status Capsule (10px rounded rectangle, NOT a pill)
                HStack(spacing: 8) {
                    Circle()
                        .fill(SlipTheme.upiGreen)
                        .frame(width: 7, height: 7)
                        .scaleEffect(isPulsing ? 1.25 : 0.85)
                        .opacity(isPulsing ? 1.0 : 0.6)
                    Text("SCANNING TICKET / PASS")
                        .font(SlipTheme.labelMono(11, weight: .semibold))
                        .tracking(1.0)
                        .foregroundStyle(SlipTheme.upiGreen)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(SlipTheme.canvasLowest.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(SlipTheme.upiGreen.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 6)
                )

                Spacer()

                // Flash / Torch Toggle Button (14px rounded rectangle)
                Button {
                    isTorchOn.toggle()
                    SlipHaptics.scrollTick()
                } label: {
                    Image(systemName: isTorchOn ? "bolt.slash.fill" : "bolt.fill")
                        .font(.slipSystem(size: 16, weight: .semibold))
                        .foregroundStyle(isTorchOn ? Color.black : SlipTheme.ink)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isTorchOn ? Color.white : SlipTheme.cardHigh.opacity(0.65))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(isTorchOn ? Color.clear : SlipTheme.glassBorder, lineWidth: 1)
                                )
                                .shadow(color: isTorchOn ? Color.white.opacity(0.35) : Color.clear, radius: 8)
                        )
                }
                .buttonStyle(.plain)
            }

            // PassKit AI OCR Active Banner (12px rounded rectangle)
            HStack(spacing: 6) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.slipSystem(size: 14, weight: .semibold))
                    .foregroundStyle(SlipTheme.upiGreen)
                Text("PassKit AI OCR Active")
                    .font(SlipTheme.labelMono(11, weight: .medium))
                    .foregroundStyle(SlipTheme.ink)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(SlipTheme.cardHigh.opacity(0.70))
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

            // Primary: Import from Photos (16px rounded rectangle, NOT a pill)
            PhotosPicker(selection: $photoItem, matching: .images) {
                HStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.slipSystem(size: 18, weight: .semibold))
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
                        .shadow(color: .black.opacity(0.4), radius: 10, y: 4)
                )
            }
            .buttonStyle(.plain)

            // Split Grid: Import from PDF & Enter Details (16px rounded rectangles)
            HStack(spacing: 10) {
                Button {
                    showFileImporter = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.text")
                            .font(.slipSystem(size: 15))
                            .foregroundStyle(SlipTheme.muted)
                        Text("Import PDF")
                            .font(SlipTheme.labelMono(12, weight: .medium))
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

                Button {
                    onManualEntry?() ?? onCancel()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "keyboard")
                            .font(.slipSystem(size: 15))
                            .foregroundStyle(SlipTheme.muted)
                        Text("Enter Details")
                            .font(SlipTheme.labelMono(12, weight: .medium))
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
            }

            // Cancel action link
            Button(action: onCancel) {
                Text("Cancel")
                    .font(SlipTheme.inter(14, weight: .semibold))
                    .foregroundStyle(SlipTheme.muted)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .buttonStyle(.plain)

            // iOS Home Indicator
            Capsule()
                .fill(Color.white.opacity(0.30))
                .frame(width: 130, height: 4)
                .padding(.top, 4)
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

// MARK: - Viewfinder Corner Brackets Shape (Exact 16px corner radius contour)

struct ViewfinderCornerBrackets: Shape {
    var cornerRadius: CGFloat = 16
    var bracketLength: CGFloat = 28

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = cornerRadius
        let l = bracketLength
        let w = rect.width
        let h = rect.height

        // Top Left
        path.move(to: CGPoint(x: 0, y: l))
        path.addLine(to: CGPoint(x: 0, y: r))
        path.addQuadCurve(to: CGPoint(x: r, y: 0), control: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: l, y: 0))

        // Top Right
        path.move(to: CGPoint(x: w - l, y: 0))
        path.addLine(to: CGPoint(x: w - r, y: 0))
        path.addQuadCurve(to: CGPoint(x: w, y: r), control: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w, y: l))

        // Bottom Right
        path.move(to: CGPoint(x: w, y: h - l))
        path.addLine(to: CGPoint(x: w, y: h - r))
        path.addQuadCurve(to: CGPoint(x: w - r, y: h), control: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: w - l, y: h))

        // Bottom Left
        path.move(to: CGPoint(x: l, y: h))
        path.addLine(to: CGPoint(x: r, y: h))
        path.addQuadCurve(to: CGPoint(x: 0, y: h - r), control: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: 0, y: h - l))

        return path
    }
}

// MARK: - Simulated Camera Feed for Simulator

/// Renders a realistic camera feed with a generic digital ticket / pass under viewfinder when hardware camera is unavailable.
struct SimulatedCameraFeedView: View {
    var onSimulateScan: () -> Void

    var body: some View {
        ZStack {
            // Ambient camera background
            LinearGradient(
                colors: [
                    Color(hex: 0x121417),
                    Color(hex: 0x090a0c),
                    Color(hex: 0x050507)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Realistic Generic Pass under the camera lens
            Button(action: {
                SlipHaptics.scanSuccess()
                onSimulateScan()
            }) {
                VStack(spacing: 12) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Digital Pass / Ticket")
                                .font(SlipTheme.headlineSM())
                                .foregroundStyle(.white)
                            Text("GENERAL ACCESS · PASS #8492")
                                .font(SlipTheme.labelMono())
                                .foregroundStyle(SlipTheme.muted)
                        }
                        Spacer()
                        Image(systemName: "ticket.fill")
                            .font(.slipSystem(size: 20))
                            .foregroundStyle(SlipTheme.upiGreen)
                    }

                    Divider().background(Color.white.opacity(0.15))

                    // Time, Gate, Access
                    HStack {
                        VStack(alignment: .leading) {
                            Text("TIME").font(.slipSystem(size: 9, weight: .bold)).foregroundStyle(SlipTheme.muted)
                            Text("18:45").font(SlipTheme.headlineSM()).foregroundStyle(.white)
                        }
                        Spacer()
                        VStack(alignment: .center) {
                            Text("GATE").font(.slipSystem(size: 9, weight: .bold)).foregroundStyle(SlipTheme.muted)
                            Text("04B").font(SlipTheme.headlineSM()).foregroundStyle(.white)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("ACCESS").font(.slipSystem(size: 9, weight: .bold)).foregroundStyle(SlipTheme.muted)
                            Text("VIP 14A").font(SlipTheme.headlineSM()).foregroundStyle(SlipTheme.upiGreen)
                        }
                    }

                    // Simulated 2D Barcode
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.95))
                            .frame(height: 70)

                        VStack(spacing: 4) {
                            HStack(spacing: 3) {
                                ForEach(0..<32, id: \.self) { i in
                                    Rectangle()
                                        .fill(Color.black)
                                        .frame(width: (i % 3 == 0 || i % 7 == 0) ? 3 : 1.5, height: 40)
                                }
                            }
                            Text("SLIP-PASS-SAMPLE-ENTRY-CODE-128")
                                .font(.slipSystem(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.black.opacity(0.75))
                        }
                    }

                    // Simulator Hint
                    HStack(spacing: 4) {
                        Image(systemName: "hand.tap.fill")
                            .font(.slipSystem(size: 11))
                        Text("Tap pass to simulate barcode scan")
                            .font(.slipSystem(size: 11, weight: .medium))
                    }
                    .foregroundStyle(SlipTheme.upiGreen)
                    .padding(.top, 4)
                }
                .padding(18)
                .frame(width: 260)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: 0x1c1e24).opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.6), radius: 20)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Hardware Camera & Torch Representable

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
