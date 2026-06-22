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
    public func fetchUsers(count: Int) async throws -> [TestUser] {
        let token = try await maskinporten.accessToken(scope: Self.scope)

        var components = URLComponents(string: Self.baseURL)!
        components.queryItems = [URLQueryItem(name: "antall", value: "\(count)")]

        var req = URLRequest(url: components.url!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw TenorError.httpError(statusCode: http.statusCode, body: body)
        }

        let result = try JSONDecoder().decode(TenorResultat.self, from: data)
        let users = (result.dokumentListe ?? []).compactMap { TestUser(tenorPerson: $0) }

        if users.isEmpty { throw TenorError.noResults }
        return users
    }
}
