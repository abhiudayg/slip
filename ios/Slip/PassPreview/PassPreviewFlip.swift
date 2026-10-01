import SwiftUI
import UIKit

/// Wallet-style 3D flip: front face + info (`i`) reveals secondary fields on the back.
struct PassFlipContainer<Front: View>: View {
    var brandId: String = "generic"
    let brandTitle: String
    let backRows: [PassBackRow]
    /// Optional fields for UPI / dining "Pay Now" on the back face.
    var payFields: [String: String] = [:]
    @ViewBuilder var front: () -> Front

    @State private var flipped = false
    @State private var showBackSheet = false

    var body: some View {
        ZStack {
            front()
                .opacity(flipped ? 0 : 1)
                .rotation3DEffect(.degrees(flipped ? -180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.65)
                .accessibilityHidden(flipped)

            PassBackFace(
                brandId: brandId,
                brandTitle: brandTitle,
                rows: backRows,
                payFields: payFields,
                onOpenFullSheet: { showBackSheet = true },
                onDone: {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                        flipped = false
                    }
                }
            )
            .opacity(flipped ? 1 : 0)
            .rotation3DEffect(.degrees(flipped ? 0 : 180), axis: (x: 0, y: 1, z: 0), perspective: 0.65)
            .accessibilityHidden(!flipped)
        }
        .overlay(alignment: .bottomTrailing) {
            if !flipped {
                Button {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                        flipped = true
                    }
                    SlipHaptics.scrollTick()
                } label: {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))
                        .shadow(color: .black.opacity(0.45), radius: 4, y: 1)
                        .padding(20)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Show pass details")
            }
        }
        .sheet(isPresented: $showBackSheet) {
            PassBackDetailsSheet(
                brandId: brandId,
                brandTitle: brandTitle,
                fields: payFields
            )
        }
    }
}

struct PassBackFace: View {
    var brandId: String = "generic"
    let brandTitle: String
    let rows: [PassBackRow]
    var payFields: [String: String] = [:]
    var onOpenFullSheet: (() -> Void)? = nil
    var onDone: () -> Void

    var body: some View {
        let palette = PassPalettes.resolved(templateId: brandId)
        VStack(spacing: 12) {
            PassMetaBar(left: "PASS DETAILS", right: "FLIP BACK", tint: palette.accentSoft)
            PassShell(palette: palette) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(brandTitle)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Spacer()
                        Button("Done", action: onDone)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(palette.accentSoft)
                    }

                    // Button to open full Stitch back-of-pass sheet
                    if let onOpenFullSheet {
                        Button(action: onOpenFullSheet) {
                            HStack {
                                Image(systemName: "list.bullet.rectangle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(palette.accentSoft)
                                Text("Full Pass Details & Logistics")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(palette.accent.opacity(0.3), lineWidth: 1))
                            )
                        }
                        .buttonStyle(.plain)
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
                                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(red: 0.35, green: 0.85, blue: 0.55)))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Pay now with UPI")
                        .accessibilityHint("Opens Google Pay, PhonePe, or another UPI app")
                    }

                    Text("Pass Details")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))

                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            if rows.isEmpty {
                                Text("Address, Wi‑Fi, host, and other secondary fields show here when filled.")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.65))
                            } else {
                                ForEach(rows) { row in
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(row.label.uppercased())
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(palette.accentSoft.opacity(0.7))
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
                    .frame(maxHeight: 280)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Automatic Updates")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Wallet can refresh this pass when Slip syncs booking changes.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    .padding(.top, 2)

                    Text("Terms apply as shown by issuing brand. Slip SecurePass™ VAS 2.0")
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
                    priorBrightness = ScreenBrightness.current
                    ScreenBrightness.set(1.0)
                }
                .onDisappear {
                    if let priorBrightness {
                        ScreenBrightness.set(priorBrightness)
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
