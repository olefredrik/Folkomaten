import SwiftUI
import AppKit
import UniformTypeIdentifiers
import TestborgerKit

/// Hovedvinduet som vises når man klikker menylinje-ikonet.
struct MenuContentView: View {
    @EnvironmentObject private var store: TestUserStore
    @StateObject private var loginItem = LoginItemController()
    @Environment(\.openWindow) private var openWindow
    @State private var search = ""
    @State private var onlyFavorites = false
    @State private var copiedFnr: String?
    @State private var isFetchingFromTenor = false
    @State private var tenorErrorMessage: String?

    private var results: [TestUser] {
        store.filtered(search: search, onlyFavorites: onlyFavorites)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            list
            Divider()
            dataActions
            Divider()
            footer
        }
        .frame(width: 400, height: 480)
        .alert("Tenor-feil", isPresented: Binding(
            get: { tenorErrorMessage != nil },
            set: { if !$0 { tenorErrorMessage = nil } }
        )) {
            Button("OK") { tenorErrorMessage = nil }
        } message: {
            Text(tenorErrorMessage ?? "")
        }
    }

    // MARK: - Topp

    private var header: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Søk navn eller fødselsnummer", text: $search)
                    .textFieldStyle(.plain)
                if !search.isEmpty {
                    Button {
                        search = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(8)
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))

            Picker("", selection: $onlyFavorites) {
                Text("Alle").tag(false)
                Text("Favoritter").tag(true)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .padding(10)
    }

    // MARK: - Liste

    private var list: some View {
        Group {
            if results.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: emptyStateIcon)
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text(emptyStateText)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 24)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(results) { user in
                            UserRowView(
                                user: user,
                                isCopied: copiedFnr == user.fnr,
                                copy: { copy(user) }
                            )
                            Divider()
                        }
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var emptyStateIcon: String {
        if store.users.isEmpty { return "person.crop.circle.badge.plus" }
        return onlyFavorites ? "star" : "person.slash"
    }

    private var emptyStateText: String {
        if store.users.isEmpty {
            return "Ingen testbrukere. Last inn en fil eller generer nye nedenfor."
        }
        return onlyFavorites ? "Ingen favoritter ennå" : "Ingen treff"
    }

    // MARK: - Testbrukere (generer → bestill → last inn)

    private var dataActions: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Testbrukere")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Spacer()

                Menu {
                    if !store.isShowingEmbedded {
                        Button("Last inn eksempelbrukere") { store.loadEmbedded() }
                        Divider()
                    }
                    Button("Tøm liste", role: .destructive) { store.clear() }
                        .disabled(store.users.isEmpty)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .help("Flere valg for lista")
            }

            HStack(spacing: 8) {
                Menu {
                    ForEach([10, 25, 50, 100], id: \.self) { count in
                        Button("\(count) brukere") { fetchFromTenor(count: count) }
                    }
                    Divider()
                    Button("Innstillinger…") { openWindow(id: "maskinporten-settings") }
                } label: {
                    if isFetchingFromTenor {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("Hent fra Tenor…", systemImage: "arrow.down.circle")
                    }
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .disabled(isFetchingFromTenor)
                .help("1. Hent testbrukere fra Tenor som finnes i syntetisk folkeregister")

                Button {
                    orderUsers()
                } label: {
                    Label("Bestill…", systemImage: "arrow.up.forward.app")
                }
                .help("2. Åpne BankID preprod (bulk-order) og last opp fila. "
                      + "Brukerne virker først etter at de er bestilt der.")

                Button {
                    loadFile()
                } label: {
                    Label("Bruk i appen…", systemImage: "tray.and.arrow.down")
                }
                .help("3. Velg den bestilte fila og ta den i bruk i appen")

                Spacer()
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    // MARK: - Bunn

    private var footer: some View {
        HStack(spacing: 8) {
            Toggle(isOn: Binding(
                get: { loginItem.isEnabled },
                set: { loginItem.setEnabled($0) }
            )) {
                Text("Start ved innlogging")
                    .font(.callout)
            }
            .toggleStyle(.checkbox)
            .disabled(!loginItem.isAvailable)
            .help(loginItem.isAvailable
                  ? "La appen starte automatisk når du logger inn"
                  : "Tilgjengelig i den ferdig bygde appen, ikke under «swift run»")

            Spacer()

            Text("\(results.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .help(store.sourceName)

            Spacer()

            Button {
                NSApp.terminate(nil)
            } label: {
                Label("Avslutt", systemImage: "power")
            }
            .buttonStyle(.borderless)
        }
        .padding(10)
    }

    // MARK: - Handlinger

    private func copy(_ user: TestUser) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(user.fnr, forType: .string)
        copiedFnr = user.fnr
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if copiedFnr == user.fnr { copiedFnr = nil }
        }
    }

    private func loadFile() {
        let panel = NSOpenPanel()
        panel.title = "Velg fil med testbrukere"
        panel.allowedContentTypes = [.plainText, .text, .commaSeparatedText]
        panel.allowsOtherFileTypes = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try store.loadFile(at: url)
            } catch {
                NSSound.beep()
            }
        }
    }

    private func fetchFromTenor(count: Int) {
        guard let credentials = KeychainCredentials.credentials() else {
            openWindow(id: "maskinporten-settings")
            return
        }
        isFetchingFromTenor = true
        tenorErrorMessage = nil
        Task {
            defer { isFetchingFromTenor = false }
            do {
                let users = try await TenorClient(credentials: credentials).fetchUsers(count: count)
                saveUsersToFile(users)
            } catch {
                tenorErrorMessage = error.localizedDescription
            }
        }
    }

    private func saveUsersToFile(_ users: [TestUser]) {
        let panel = NSSavePanel()
        panel.title = "Lagre testbrukere fra Tenor"
        panel.nameFieldStringValue = "testbrukere.txt"
        panel.allowedContentTypes = [.plainText]
        panel.allowsOtherFileTypes = true
        panel.message = "Last fila opp i BankID preprod (bulk-order) for å bestille brukerne, "
            + "og last den så inn her etterpå."
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try TestUserGenerator.fileData(for: users).write(to: url)
            } catch {
                NSSound.beep()
            }
        }
    }

    private func orderUsers() {
        guard let url = URL(string: "https://ra-preprod.bankidnorge.no/#!/bulk-order") else { return }
        NSWorkspace.shared.open(url)
    }
}
