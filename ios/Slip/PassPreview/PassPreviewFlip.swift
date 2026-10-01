import SwiftUI
import UIKit

/// Wallet-style 3D flip: front face + info (`i`) reveals secondary fields on the back.
struct PassFlipContainer<Front: View>: View {
    let brandTitle: String
    let backRows: [PassBackRow]
    /// Optional fields for UPI / dining "Pay Now" on the back face.
    var payFields: [String: String] = [:]
    @ViewBuilder var front: () -> Front

    @State private var flipped = false

    var body: some View {
        ZStack {
            front()
                .opacity(flipped ? 0 : 1)
                .rotation3DEffect(.degrees(flipped ? -180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.65)
                .accessibilityHidden(flipped)

            PassBackFace(brandTitle: brandTitle, rows: backRows, payFields: payFields) {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                    flipped = false
                }
            }
            .opacity(flipped ? 1 : 0)
            .rotation3DEffect(.degrees(flipped ? 0 : 180), axis: (x: 0, y: 1, z: 0), perspective: 0.65)
            .accessibilityHidden(!flipped)
        }
        .overlay(alignment: .topTrailing) {
            if !flipped {
                Button {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                        flipped = true
                    }
                    SlipHaptics.scrollTick()
                } label: {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))
                        .shadow(color: .black.opacity(0.45), radius: 4, y: 1)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 14)
                .padding(.top, 44)
                .accessibilityLabel("Show pass details")
            }
        }
    }
}

struct PassBackFace: View {
    let brandTitle: String
    let rows: [PassBackRow]
    var payFields: [String: String] = [:]
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            PassMetaBar(left: "PASS DETAILS", right: "BACK", tint: Color.white.opacity(0.55))
            PassShell(palette: PassPalettes.genericDark) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(brandTitle)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Spacer()
                        Button("Done", action: onDone)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.cyan.opacity(0.9))
                    }

                    if UPIPayLink.canPay(fields: payFields) {
                        Button {
                            UPIPayLink.open(fields: payFields)
                        } label: {
                            Label("Pay Now with UPI", systemImage: "indianrupeesign.circle.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Capsule().fill(Color(red: 0.35, green: 0.85, blue: 0.55)))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Pay now with UPI")
                        .accessibilityHint("Opens Google Pay, PhonePe, or another UPI app")
                    }

                    Text("More details")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))

                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            if rows.isEmpty {
                                Text("Address, Wi‑Fi, host, and other secondary fields show here when filled.")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.65))
                            } else {
                                ForEach(rows) { row in
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(row.label.uppercased())
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(.white.opacity(0.45))
                                        Text(row.value)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.white)
                                            .textSelection(.enabled)
                                    }
                                    SoftDivider(tint: Color.white.opacity(0.08))
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 360)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Automatic Updates")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Wallet can refresh this pass when Slip syncs booking changes.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    .padding(.top, 4)

                    Text("Terms apply as shown by the issuing brand. This preview is not a live PassKit back.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

/// Expands a barcode/QR preview and bumps screen brightness (Wallet-like).
struct ExpandableCodeModifier: ViewModifier {
    let alt: String
    let caption: String
    @State private var expanded = false
    @State private var priorBrightness: CGFloat?

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture { expanded = true }
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Double tap to enlarge code")
            .fullScreenCover(isPresented: $expanded) {
                ZStack {
                    Color.white.ignoresSafeArea()
                    VStack(spacing: 24) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 220, weight: .regular))
                            .foregroundStyle(.black)
                        if !alt.isEmpty {
                            Text(alt)
                                .font(.title3.monospaced().weight(.bold))
                                .foregroundStyle(.black)
                        }
                        Text(caption)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.black.opacity(0.55))
                        Button("Done") { expanded = false }
                            .font(.headline)
                            .padding(.top, 12)
                    }
                    .padding()
                }
                .onAppear {
                    priorBrightness = UIScreen.main.brightness
                    UIScreen.main.brightness = 1.0
                }
                .onDisappear {
                    if let priorBrightness {
                        UIScreen.main.brightness = priorBrightness
                    }
                }
            }
    }
}

extension View {
    func expandablePassCode(alt: String, caption: String) -> some View {
        modifier(ExpandableCodeModifier(alt: alt, caption: caption))
    }
}
