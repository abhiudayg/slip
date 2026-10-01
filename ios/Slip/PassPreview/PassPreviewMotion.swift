import Combine
import CoreMotion
import SwiftUI

/// Device-motion specular for Wallet-like glossy cards. Falls back to idle shimmer when unavailable.
@MainActor
final class PassMotionGlow: ObservableObject {
    static let shared = PassMotionGlow()

    @Published private(set) var roll: Double = 0
    @Published private(set) var pitch: Double = 0
    @Published private(set) var active = false

    private let manager = CMMotionManager()
    private var subscribers = 0

    func retain() {
        subscribers += 1
        guard subscribers == 1 else { return }
        start()
    }

    func release() {
        subscribers = max(0, subscribers - 1)
        guard subscribers == 0 else { return }
        stop()
    }

    private func start() {
        guard manager.isDeviceMotionAvailable else {
            active = false
            return
        }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            // Soften attitude into a gentle highlight offset.
            self.roll = max(-0.55, min(0.55, data.attitude.roll))
            self.pitch = max(-0.45, min(0.45, data.attitude.pitch))
            self.active = true
        }
    }

    private func stop() {
        manager.stopDeviceMotionUpdates()
        active = false
        roll = 0
        pitch = 0
    }
}

struct PassMotionShimmerOverlay: View {
    @ObservedObject private var motion = PassMotionGlow.shared

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let idle = (sin(t * 0.9) + 1) / 2
            let mx = motion.active ? (motion.roll + 1) / 2 : idle
            let my = motion.active ? (motion.pitch + 1) / 2 : 0.35
            LinearGradient(
                colors: [
                    Color.white.opacity(0.02),
                    Color.white.opacity(0.20),
                    Color.white.opacity(0.06),
                    .clear
                ],
                startPoint: UnitPoint(x: mx - 0.35, y: my - 0.2),
                endPoint: UnitPoint(x: mx + 0.35, y: my + 0.55)
            )
            .blendMode(.screen)
        }
        .onAppear { motion.retain() }
        .onDisappear { motion.release() }
    }
}
