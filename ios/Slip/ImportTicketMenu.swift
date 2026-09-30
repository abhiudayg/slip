import SwiftUI

/// Custom import chooser with dimmed backdrop + spring presentation
/// (replaces system confirmationDialog for a more focused, fluid feel).
struct ImportTicketMenu: View {
    @Binding var isPresented: Bool
    var onScan: () -> Void
    var onPhoto: () -> Void
    var onPDF: () -> Void
    var onTemplates: () -> Void

    @State private var backdropIn = false
    @State private var cardIn = false
    @State private var optionsIn = false

    var body: some View {
        ZStack {
            // Backdrop — blur + dim so marketplace falls away
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                Color.black.opacity(0.58)
            }
            .ignoresSafeArea()
            .opacity(backdropIn ? 1 : 0)
            .onTapGesture { dismiss() }
            .accessibilityLabel("Dismiss import menu")

            VStack {
                Spacer(minLength: 0)
                menuCard
                    .padding(.horizontal, 22)
                    .padding(.bottom, 28)
                    .offset(y: cardIn ? 0 : 56)
                    .scaleEffect(cardIn ? 1 : 0.92, anchor: .bottom)
                    .opacity(cardIn ? 1 : 0)
            }
            .padding(.bottom, 72) // clear floating dock
        }
        .allowsHitTesting(isPresented)
        .onAppear { animateIn() }
        .onChange(of: isPresented) { _, show in
            if show { animateIn() } else { resetFlags() }
        }
    }

    private var menuCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Import ticket")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(SlipTheme.ink)
                    Text("Import a screenshot or booking PDF, scan a code, or pick a template.")
                        .font(.footnote)
                        .foregroundStyle(SlipTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SlipTheme.muted)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }

            VStack(spacing: 10) {
                optionButton(
                    title: "Scan QR / barcode",
                    systemImage: "qrcode.viewfinder",
                    delay: 0.02,
                    action: { choose(onScan) }
                )
                optionButton(
                    title: "Photo / screenshot",
                    systemImage: "photo.on.rectangle.angled",
                    delay: 0.06,
                    action: { choose(onPhoto) }
                )
                optionButton(
                    title: "PDF booking",
                    systemImage: "doc.richtext",
                    delay: 0.10,
                    action: { choose(onPDF) }
                )
                optionButton(
                    title: "Browse templates",
                    systemImage: "square.grid.2x2",
                    delay: 0.14,
                    action: { choose(onTemplates) }
                )
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.28),
                                    Color.white.opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.5), radius: 32, y: 18)
        )
    }

    private func optionButton(
        title: String,
        systemImage: String,
        delay: Double,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(SlipTheme.accentSoft)
                    .frame(width: 28)
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(SlipTheme.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SlipTheme.muted.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ImportOptionPressStyle())
        .opacity(optionsIn ? 1 : 0)
        .offset(y: optionsIn ? 0 : 18)
        .scaleEffect(optionsIn ? 1 : 0.96, anchor: .bottom)
        .animation(
            .spring(response: 0.55, dampingFraction: 0.78).delay(optionsIn ? delay : 0),
            value: optionsIn
        )
    }

    private func animateIn() {
        resetFlags()
        // Backdrop leads slightly so focus settles before the card arrives.
        withAnimation(.easeOut(duration: 0.28)) {
            backdropIn = true
        }
        withAnimation(.spring(response: 0.58, dampingFraction: 0.82).delay(0.04)) {
            cardIn = true
        }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.10)) {
            optionsIn = true
        }
    }

    private func animateOut(completion: @escaping () -> Void) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.92)) {
            optionsIn = false
            cardIn = false
        }
        withAnimation(.easeIn(duration: 0.22).delay(0.04)) {
            backdropIn = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            completion()
        }
    }

    private func resetFlags() {
        backdropIn = false
        cardIn = false
        optionsIn = false
    }

    private func dismiss() {
        animateOut { isPresented = false }
    }

    private func choose(_ action: @escaping () -> Void) {
        animateOut {
            isPresented = false
            // Yield so photosPicker / fileImporter present after menu teardown.
            Task { @MainActor in
                await Task.yield()
                action()
            }
        }
    }
}

private struct ImportOptionPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.78), value: configuration.isPressed)
    }
}
