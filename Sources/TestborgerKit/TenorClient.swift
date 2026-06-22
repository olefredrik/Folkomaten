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
    // Oppdater path ved behov når scopet er aktivert og endepunktet er bekreftet.
    private static let baseURL = "https://testdata.api.skatteetaten.no/api/testnorge/v2/freg"
    private static let scope   = "skatteetaten:testnorge/testdata.read"

    private let maskinporten: MaskinportenClient

    public init(credentials: MaskinportenCredentials) {
        self.maskinporten = MaskinportenClient(credentials: credentials)
    }

    /// Henter `count` tilfeldige testpersoner fra Tenor og returnerer dem som `TestUser`.
    public func fetchUsers(count: Int) async throws -> [TestUser] {
        let token = try await maskinporten.accessToken(scope: Self.scope)

        var components = URLComponents(string: Self.baseURL)!
        components.queryItems = [URLQueryItem(name: "antall", value: "\(count)")]

        var req = URLRequest(url: components.url!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw TenorError.httpError(statusCode: http.statusCode, body: body)
        }

        // Tenor returnerer antakelig en JSON-array av FREG-dokumenter.
        // Dersom responsen er et wrapper-objekt med "data"-felt, bytt til:
        //   struct Wrapper: Decodable { let data: [TenorPerson] }
        //   let persons = try JSONDecoder().decode(Wrapper.self, from: data).data
        let persons = try JSONDecoder().decode([TenorPerson].self, from: data)
        let users = persons.compactMap { TestUser(tenorPerson: $0) }

        if users.isEmpty { throw TenorError.noResults }
        return users
    }
}
