import Foundation

/// Lagrer Maskinporten-legitimasjon i en fil under Application Support.
///
/// Vi bruker fil og ikke nøkkelringen fordi appen er ad-hoc-signert: signaturen endrer seg
/// for hver build, så macOS ber om nøkkelring-tilgang på nytt hver gang. Fila leses og skrives
/// kun av brukeren (rettigheter 0600). Nøkkelen er en test-nøkkel mot Maskinporten ver2.
public enum CredentialStore {

    private struct Stored: Codable {
        var clientId: String
        var kid: String
        var privateKeyPEM: String
    }

    private static var fileURL: URL {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Folkomaten", isDirectory: true)
        return dir.appendingPathComponent("credentials.json")
    }

    public static var clientId: String? {
        get { load()?.clientId }
        set { update { $0.clientId = newValue ?? "" } }
    }

    public static var kid: String? {
        get { load()?.kid }
        set { update { $0.kid = newValue ?? "" } }
    }

    public static var privateKeyPEM: String? {
        get { load()?.privateKeyPEM }
        set { update { $0.privateKeyPEM = newValue ?? "" } }
    }

    public static var isConfigured: Bool {
        guard let s = load() else { return false }
        return !s.clientId.isEmpty && !s.privateKeyPEM.isEmpty
    }

    public static func credentials() -> MaskinportenCredentials? {
        guard let s = load(), !s.clientId.isEmpty, !s.privateKeyPEM.isEmpty else { return nil }
        return MaskinportenCredentials(
            clientId: s.clientId,
            privateKeyPEM: s.privateKeyPEM,
            kid: s.kid.isEmpty ? nil : s.kid
        )
    }

    // MARK: - Privat

    private static func load() -> Stored? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(Stored.self, from: data)
    }

    private static func update(_ mutate: (inout Stored) -> Void) {
        var stored = load() ?? Stored(clientId: "", kid: "", privateKeyPEM: "")
        mutate(&stored)
        save(stored)
    }

    private static func save(_ stored: Stored) {
        let fm = FileManager.default
        let dir = fileURL.deletingLastPathComponent()
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)

        guard let data = try? JSONEncoder().encode(stored) else { return }
        try? data.write(to: fileURL, options: .atomic)
        // Begrens tilgang til kun eieren.
        try? fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }
}
