import SwiftUI

/// Typed field control for pass schemas. Backing store remains a string for PassKit.
struct PassFieldEditor: View {
    let key: String
    let templateId: String
    @Binding var text: String
    /// Compact grid cell vs form/summary row.
    var style: Style = .form

    enum Style {
        case form
        case compact
        case summary
    }

    private var kind: BrandFields.FieldKind { BrandFields.kind(for: key) }
    private var label: String { BrandFields.label(for: key, templateId: templateId) }

    var body: some View {
        Group {
            switch kind {
            case .date:
                dateControl(includesTime: false)
            case .time:
                timeControl
            case .datetime:
                dateControl(includesTime: true)
            case .latitude, .longitude, .decimal, .currency, .number:
                numericField
            default:
                textField
            }
        }
    }

    private var textField: some View {
        TextField(label, text: $text, axis: multilineAxis)
            .font(fieldFont)
            .foregroundStyle(SlipTheme.ink)
            .textInputAutocapitalization(capitalization)
            .autocorrectionDisabled(kind == .code || kind == .location)
            .keyboardType(keyboard)
            .textContentType(contentType)
            .submitLabel(.done)
    }

    private var numericField: some View {
        TextField(label, text: $text)
            .font(fieldFont)
            .foregroundStyle(SlipTheme.ink)
            .keyboardType(kind == .number ? .numberPad : .decimalPad)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .monospacedDigit()
    }

    @ViewBuilder
    private func dateControl(includesTime: Bool) -> some View {
        HStack(spacing: 8) {
            TextField(label, text: $text, axis: .vertical)
                .font(fieldFont)
                .foregroundStyle(SlipTheme.ink)
                .lineLimit(2)
            DatePicker(
                "",
                selection: dateBinding(includesTime: includesTime),
                displayedComponents: includesTime ? [.date, .hourAndMinute] : [.date]
            )
            .labelsHidden()
            .tint(SlipTheme.accentSoft)
            .frame(width: includesTime ? 130 : 100)
        }
    }

    private var timeControl: some View {
        HStack(spacing: 8) {
            TextField(label, text: $text)
                .font(fieldFont)
                .foregroundStyle(SlipTheme.ink)
            DatePicker(
                "",
                selection: timeBinding,
                displayedComponents: [.hourAndMinute]
            )
            .labelsHidden()
            .tint(SlipTheme.accentSoft)
            .frame(width: 90)
        }
    }

    private var multilineAxis: Axis {
        if kind == .multiline || kind == .location || key == "qr_data" {
            return .vertical
        }
        return .horizontal
    }

    private var fieldFont: Font {
        switch style {
        case .compact: return .caption.weight(.semibold)
        case .summary: return .subheadline.weight(.semibold)
        case .form: return .body
        }
    }

    private var keyboard: UIKeyboardType {
        switch kind {
        case .phone: return .phonePad
        case .email: return .emailAddress
        case .url: return .URL
        case .code: return .asciiCapable
        case .location: return .default
        default: return .default
        }
    }

    private var capitalization: TextInputAutocapitalization {
        switch kind {
        case .code, .email, .url, .phone:
            return .never
        case .multiline:
            return .sentences
        default:
            return .words
        }
    }

    private var contentType: UITextContentType? {
        switch kind {
        case .email: return .emailAddress
        case .phone: return .telephoneNumber
        case .location: return .fullStreetAddress
        default: return nil
        }
    }

    private func dateBinding(includesTime: Bool) -> Binding<Date> {
        Binding(
            get: {
                PassFieldFormatting.parseDate(text) ?? Date()
            },
            set: { newValue in
                text = includesTime
                    ? PassFieldFormatting.formatDateTime(newValue)
                    : PassFieldFormatting.formatDate(newValue)
            }
        )
    }

    private var timeBinding: Binding<Date> {
        Binding(
            get: { PassFieldFormatting.parseTime(text) ?? Date() },
            set: { text = PassFieldFormatting.formatTime($0) }
        )
    }
}

enum PassFieldFormatting {
    private static let dateOut: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE, MMM d"
        return f
    }()

    private static let dateTimeOut: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE, MMM d h:mm a"
        return f
    }()

    private static let timeOut: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "h:mm a"
        return f
    }()

    static func formatDate(_ date: Date) -> String { dateOut.string(from: date) }
    static func formatDateTime(_ date: Date) -> String { dateTimeOut.string(from: date) }
    static func formatTime(_ date: Date) -> String { timeOut.string(from: date) }

    static func parseDate(_ raw: String) -> Date? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let d = PassExpiration.parseFlexibleDate(trimmed) { return d }
        for f in [dateOut, dateTimeOut] {
            if let d = f.date(from: trimmed) { return d }
        }
        return nil
    }

    static func parseTime(_ raw: String) -> Date? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let d = timeOut.date(from: trimmed) { return d }
        // "After 1:00 PM" / "By 11:00 AM"
        let cleaned = trimmed.replacingOccurrences(
            of: #"(?i)\b(after|by|before)\b"#,
            with: "",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespaces)
        if let d = timeOut.date(from: cleaned) { return d }
        if let full = PassExpiration.parseFlexibleDate(trimmed) { return full }
        return nil
    }
}
