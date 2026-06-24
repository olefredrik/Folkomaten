import SwiftUI
import FolkomatenKit

struct MaskinportenSettingsView: View {
    private func closeWindow() {
        NSApp.windows.first { $0.title == "Innstillinger" }?.close()
    }

    @State private var clientId      = CredentialStore.clientId ?? ""
    @State private var kid           = CredentialStore.kid ?? ""
    @State private var privateKeyPEM = CredentialStore.privateKeyPEM ?? ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Hurtigtast")
                    .font(.headline)
                HStack {
                    Text("Åpne Folkomaten")
                    Spacer()
                    ShortcutRecorderView()
                }
                Text("Virker overalt – også når menylinje-ikonet er skjult bak notch-en. "
                     + "Endres med en gang du trykker ny kombinasjon (uavhengig av Lagre).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Text("Maskinporten")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                Text("Klient ID")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", text: $clientId)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Nøkkel-ID (kid)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("kid fra nøkkelen i Samarbeidsportalen", text: $kid)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Privat nøkkel (PEM)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $privateKeyPEM)
                    .font(.system(.caption, design: .monospaced))
                    .frame(height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.secondary.opacity(0.3))
                    )
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Slik setter du opp:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("1. Opprett en klient i selvbetjeningen og legg til en generert nøkkel.")
                    Text("2. Lim inn privatnøkkelen du får (PEM) i feltet over.")
                    Text("3. Kopier Klient ID og Nøkkel-ID (kid) fra portalen.")
                    Text("4. Klikk Lagre.")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Link("Åpne selvbetjeningen",
                         destination: URL(string: "https://sjolvbetjening.test.samarbeid.digdir.no/")!)
                    Link("Om Tenor-tilgang",
                         destination: URL(string: "https://skatteetaten.github.io/testnorge-tenor-dokumentasjon/")!)
                }
                .font(.caption)
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
        .frame(width: 440, height: 580)
    }

    private func save() {
        CredentialStore.clientId = clientId.trimmingCharacters(in: .whitespacesAndNewlines)
        CredentialStore.kid = kid.trimmingCharacters(in: .whitespacesAndNewlines)
        CredentialStore.privateKeyPEM = privateKeyPEM.trimmingCharacters(in: .whitespacesAndNewlines)
        closeWindow()
    }
}
