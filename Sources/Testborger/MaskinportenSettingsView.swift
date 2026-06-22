import SwiftUI
import CryptoKit
import TestborgerKit

struct MaskinportenSettingsView: View {
    private func closeWindow() {
        NSApp.windows.first { $0.title == "Maskinporten-innstillinger" }?.close()
    }

    @State private var clientId      = KeychainCredentials.clientId ?? ""
    @State private var privateKeyPEM = KeychainCredentials.privateKeyPEM ?? ""
    @State private var jwkCopied     = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Maskinporten-innstillinger")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                Text("Client ID")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", text: $clientId)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Privat nøkkel (PEM / PKCS#8)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $privateKeyPEM)
                    .font(.system(.caption, design: .monospaced))
                    .frame(height: 110)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.secondary.opacity(0.3))
                    )
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Første gang? Generer et nøkkelpar:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("1. Klikk «Generer og kopier JWK» — nøklene lages og privat nøkkel fylles inn automatisk.")
                    Text("2. Lim inn JWK (fra utklippstavlen) som en nøkkel på klienten din i Samarbeidsportalen.")
                    Text("3. Fyll inn Client ID fra Samarbeidsportalen over.")
                    Text("4. Klikk Lagre.")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Button(jwkCopied ? "JWK kopiert!" : "Generer og kopier JWK") {
                    generateKeyPair()
                }
                .disabled(jwkCopied)
                .padding(.top, 2)
            }

            Spacer()

            HStack {
                Button("Avbryt") { closeWindow() }
                Spacer()
                Button("Lagre") { save() }
                    .buttonStyle(.borderedProminent)
                    .disabled(clientId.trimmingCharacters(in: .whitespaces).isEmpty
                              || privateKeyPEM.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 440, height: 430)
    }

    private func save() {
        KeychainCredentials.clientId = clientId.trimmingCharacters(in: .whitespacesAndNewlines)
        KeychainCredentials.privateKeyPEM = privateKeyPEM.trimmingCharacters(in: .whitespacesAndNewlines)
        closeWindow()
    }

    private func generateKeyPair() {
        let key = P256.Signing.PrivateKey()
        privateKeyPEM = key.pemRepresentation

        let raw = Array(key.publicKey.rawRepresentation)  // 64 bytes: x(32) || y(32)
        guard raw.count == 64 else { return }
        let x = Data(raw[0..<32]).base64url
        let y = Data(raw[32..<64]).base64url
        let jwk: [String: Any] = ["kty": "EC", "crv": "P-256", "x": x, "y": y]

        if let data = try? JSONSerialization.data(withJSONObject: jwk, options: .prettyPrinted),
           let str = String(data: data, encoding: .utf8) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(str, forType: .string)
            jwkCopied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { jwkCopied = false }
        }
    }
}
