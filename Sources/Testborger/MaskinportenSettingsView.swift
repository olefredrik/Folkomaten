import SwiftUI
import CryptoKit
import TestborgerKit

struct MaskinportenSettingsView: View {
    @Binding var isPresented: Bool

    @State private var clientId     = KeychainCredentials.clientId ?? ""
    @State private var privateKeyPEM = KeychainCredentials.privateKeyPEM ?? ""
    @State private var jwkCopied    = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Maskinporten-legitimasjon")
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
                Text("Generer nytt ES256-nøkkelpar")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Text("Lager et nytt nøkkelpar, fyller inn den private nøkkelen over, "
                     + "og kopierer public key (JWK) til utklippstavlen for opplasting i Samarbeidsportalen.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button(jwkCopied ? "JWK kopiert!" : "Generer og kopier JWK") {
                    generateKeyPair()
                }
                .disabled(jwkCopied)
            }

            Spacer()

            HStack {
                Button("Avbryt") { isPresented = false }
                Spacer()
                Button("Lagre") { save() }
                    .buttonStyle(.borderedProminent)
                    .disabled(clientId.trimmingCharacters(in: .whitespaces).isEmpty
                              || privateKeyPEM.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 420, height: 400)
    }

    private func save() {
        KeychainCredentials.clientId = clientId.trimmingCharacters(in: .whitespacesAndNewlines)
        KeychainCredentials.privateKeyPEM = privateKeyPEM.trimmingCharacters(in: .whitespacesAndNewlines)
        isPresented = false
    }

    private func generateKeyPair() {
        let key = P256.Signing.PrivateKey()
        let pem = key.pemRepresentation
        privateKeyPEM = pem

        let raw = key.publicKey.rawRepresentation     // 64 bytes: x(32) || y(32)
        let x = raw[0..<32].base64url
        let y = raw[32..<64].base64url
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
