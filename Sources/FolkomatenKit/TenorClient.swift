import Foundation

public enum TenorError: LocalizedError {
    case noResults
    case httpError(statusCode: Int, body: String)

    public var errorDescription: String? {
        switch self {
        case .noResults:
            return "Tenor returnerte ingen testbrukere. Prøv igjen eller reduser antallet."
        case .httpError(let code, let body):
            return "Tenor svarte med feil \(code): \(body)"
        }
    }
}

public struct TenorClient: Sendable {
    /// Søk i folkeregister-kilden (`freg`) i Tenor testdatasøk.
    private static let baseURL = "https://testdata.api.skatteetaten.no/api/testnorge/v2/soek/freg"
    private static let scope   = "skatteetaten:testnorge/testdata.read"

    private let maskinporten: MaskinportenClient

    public init(credentials: MaskinportenCredentials) {
        self.maskinporten = MaskinportenClient(credentials: credentials)
    }

    /// Henter `count` testpersoner fra Tenor og returnerer dem som `TestUser`.
    ///
    /// Døde/ikke-bosatte holdes ute server-side via KQL (`personstatus:bosatt`).
    /// D-numre og mindreårige siles bort klientside med `TestUserFilter`, slik at
    /// alle returnerte brukere kan bestilles som aktive BankID-testbrukere. Vi
    /// overhenter litt for at antallet skal holde etter filtrering.
    public func fetchUsers(count: Int) async throws -> [TestUser] {
        let token = try await maskinporten.accessToken(scope: Self.scope)

        let requested = min(max(count * 2, count), 100)

        var components = URLComponents(string: Self.baseURL)!
        // Be om kun feltene vi trenger. Uten `vis` returnerer freg-søket bare metadata-id.
        components.queryItems = [
            URLQueryItem(name: "antall", value: "\(requested)"),
            URLQueryItem(name: "kql", value: "personstatus:bosatt and identifikatorType:foedselsnummer"),
            URLQueryItem(name: "vis", value: "fornavn"),
            URLQueryItem(name: "vis", value: "etternavn"),
            URLQueryItem(name: "vis", value: "id"),
        ]

        var req = URLRequest(url: components.url!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw TenorError.httpError(statusCode: http.statusCode, body: body)
        }

        let result = try JSONDecoder().decode(TenorResultat.self, from: data)
        let now = Date()
        let users = (result.dokumentListe ?? [])
            .compactMap { TestUser(tenorPerson: $0) }
            .filter { TestUserFilter.isOrderable($0.fnr, on: now) }
            .prefix(count)

        if users.isEmpty { throw TenorError.noResults }
        return Array(users)
    }
}
