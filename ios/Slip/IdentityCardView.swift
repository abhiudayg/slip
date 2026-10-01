import SwiftUI

/// Secure ID face shown beside a boarding pass (swipe in Pass Details).
struct IdentityCardView: View {
    let document: IdentityDocument

    var body: some View {
        let p = PassPalettes.genericDark
        VStack(spacing: 12) {
            PassMetaBar(left: "SLIP IDENTITY VAULT", right: "ENCRYPTED", tint: p.accent)
            PassShell(palette: p) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: document.kind.systemImage)
                            .font(.title2)
                            .foregroundStyle(p.accentSoft)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(document.kind.title)
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text(document.displayName)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.75))
                        }
                        Spacer()
                    }
                    SoftDivider(tint: p.accent.opacity(0.12))
                    ForEach(Array(document.fields.keys.sorted()), id: \.self) { key in
                        if let value = document.fields[key], !value.isEmpty {
                            FieldBlock(
                                label: key.replacingOccurrences(of: "_", with: " ").uppercased(),
                                value: value,
                                labelColor: p.accentSoft.opacity(0.7),
                                valueSize: 16
                            )
                        }
                    }
                    Text("For airport / IRCTC checks — swipe back to your boarding pass. DigiLocker OAuth can replace manual import when approved.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(.top, 4)
                }
                .padding(16)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(document.kind.title) identity card for \(document.displayName)")
    }
}

struct IdentityVaultSheet: View {
    @ObservedObject var store: IdentityVaultStore
    @Environment(\.dismiss) private var dismiss
    @State private var kind: IdentityKind = .aadhaar
    @State private var name = ""
    @State private var idNumber = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Add government ID") {
                    Picker("Type", selection: $kind) {
                        ForEach(IdentityKind.allCases) { k in
                            Text(k.title).tag(k)
                        }
                    }
                    TextField("Name on ID", text: $name)
                    TextField(kind == .aadhaar ? "Aadhaar (last 4 or masked)" : "ID number (masked OK)", text: $idNumber)
                        .textInputAutocapitalization(.characters)
                    Button("Save encrypted ID") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                Section("Vault") {
                    if store.documents.isEmpty {
                        Text("No IDs yet. Add a masked Aadhaar / PAN / DL for gate checks.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.documents) { doc in
                            Label(doc.displayName, systemImage: doc.kind.systemImage)
                        }
                        .onDelete { indexSet in
                            for i in indexSet {
                                try? store.delete(id: store.documents[i].id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Identity vault")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let now = Date()
        let masked: String = {
            let raw = idNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            if kind == .aadhaar, raw.count >= 4 {
                return "XXXX-XXXX-" + String(raw.suffix(4))
            }
            return raw
        }()
        let doc = IdentityDocument(
            id: UUID().uuidString,
            kind: kind,
            displayName: name.trimmingCharacters(in: .whitespacesAndNewlines),
            fields: [
                "id_number": masked,
                "note": "Imported in Slip · DigiLocker sync optional"
            ],
            createdAt: now,
            updatedAt: now
        )
        try? store.upsert(doc)
        name = ""
        idNumber = ""
        SlipHaptics.passSaved()
    }
}
