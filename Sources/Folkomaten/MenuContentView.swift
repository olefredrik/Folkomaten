import SwiftUI
import AppKit
import UniformTypeIdentifiers
import FolkomatenKit

/// Hovedvinduet som vises når man klikker menylinje-ikonet.
struct MenuContentView: View {
    @EnvironmentObject private var store: TestUserStore
    @StateObject private var loginItem = LoginItemController()
    @State private var search = ""
    @State private var onlyFavorites = false
    @State private var copiedFnr: String?
    @State private var isFetchingFromTenor = false
    @State private var tenorErrorMessage: String?
    @State private var showDataActions = false

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
        // Solid, adaptiv bakgrunn (hvit i light mode, mørk grå i dark mode) i
        // stedet for popoverens gjennomskinnelige grå – gir bedre kontrast.
        .background(Color(nsColor: .controlBackgroundColor))
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

    /// Steg-etikett med fast ikonbredde, så tallene 1/2/3 står på linje selv om
    /// SF-symbolene har ulik intrinsisk bredde.
    private func stepLabel(_ number: Int, _ title: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .frame(width: 20)
            Text("\(number). \(title)")
        }
    }

    private var dataActions: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { showDataActions.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .rotationEffect(.degrees(showDataActions ? 90 : 0))
                        Text("Nye testbrukere")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.secondary)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Hent og bestill nye testbrukere – sjelden nødvendig")

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

            if showDataActions {
                VStack(alignment: .leading, spacing: 10) {
                Menu {
                    ForEach([10, 25, 50, 100], id: \.self) { count in
                        Button("\(count) brukere") { fetchFromTenor(count: count) }
                    }
                    Divider()
                    Button("Innstillinger…") { closePanel(); SettingsWindowController.shared.show() }
                } label: {
                    if isFetchingFromTenor {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.small).frame(width: 20)
                            Text("Henter …")
                        }
                    } else {
                        stepLabel(1, "Hent fra Tenor", systemImage: "arrow.down.circle")
                    }
                }
                .menuStyle(.button)
                .menuIndicator(.hidden)
                .disabled(isFetchingFromTenor)
                .help("Hent testbrukere fra Tenor som finnes i syntetisk folkeregister")

                Button {
                    orderUsers()
                } label: {
                    stepLabel(2, "Koble til BankID", systemImage: "arrow.up.forward.app")
                }
                .help("Åpne BankID preprod (bulk-order) og last opp fila. "
                      + "Brukerne virker først etter at de er bestilt der.")

                Button {
                    loadFile()
                } label: {
                    stepLabel(3, "Last inn i appen", systemImage: "tray.and.arrow.down")
                }
                .help("Velg den bestilte fila og ta den i bruk i appen")
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
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
                closePanel()
                SettingsWindowController.shared.show()
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
            .help("Innstillinger – Maskinporten og hurtigtast")

            Button {
                NSApp.terminate(nil)
            } label: {
                Label("Avslutt", systemImage: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(.borderless)
        }
        .padding(10)
    }

    // MARK: - Handlinger

    /// Lukker det flytende panelet før vi åpner et annet vindu eller en dialog,
    /// slik at de ikke havner bak panelet (som flyter øverst).
    private func closePanel() {
        NSApp.windows.first { $0.identifier == folkomatenPanelIdentifier }?.orderOut(nil)
    }

    private func copy(_ user: TestUser) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(user.fnr, forType: .string)
        copiedFnr = user.fnr
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if copiedFnr == user.fnr { copiedFnr = nil }
        }
    }

    private func loadFile() {
        closePanel()
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
        guard let credentials = CredentialStore.credentials() else {
            closePanel()
            SettingsWindowController.shared.show()
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
        closePanel()
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
