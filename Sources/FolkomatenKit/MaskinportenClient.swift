import Foundation
import Security

public struct MaskinportenCredentials: Sendable {
    public let clientId: String
    public let privateKeyPEM: String
    /// Nøkkel-ID fra Samarbeidsportalen. Settes i JWT-headeren så Maskinporten finner riktig nøkkel.
    public let kid: String?

    public init(clientId: String, privateKeyPEM: String, kid: String?) {
        self.clientId = clientId
        self.privateKeyPEM = privateKeyPEM
        self.kid = kid
    }
}

public enum MaskinportenError: LocalizedError {
    case invalidPrivateKey
    case signingFailed(String)
    case tokenFetchFailed(statusCode: Int, body: String)

    public var errorDescription: String? {
        switch self {
        case .invalidPrivateKey:
            return "Ugyldig privat nøkkel. Forventer en RSA-nøkkel i PEM-format (PKCS#8)."
        case .signingFailed(let detail):
            return "Klarte ikke å signere token: \(detail)"
        case .tokenFetchFailed(let code, let body):
            return "Maskinporten svarte med feil \(code): \(body)"
        }
    }
}

/// Henter Maskinporten-tokens via JWT grant-flyten (RS256).
public actor MaskinportenClient {
    private static let tokenURL = URL(string: "https://test.maskinporten.no/token")!
    private static let audience = "https://test.maskinporten.no/"

    private let credentials: MaskinportenCredentials
    private var cached: (token: String, expiresAt: Date)?

    public init(credentials: MaskinportenCredentials) {
        self.credentials = credentials
    }

    /// Returnerer et gyldig access token. Bruker cachet token hvis det er mer enn 10 sek til utløp.
    public func accessToken(scope: String) async throws -> String {
        if let c = cached, c.expiresAt > Date().addingTimeInterval(10) {
            return c.token
        }
        return try await fetchFreshToken(scope: scope)
    }

    private func fetchFreshToken(scope: String) async throws -> String {
        let privateKey = try RSAKey(pem: credentials.privateKeyPEM)
        let assertion = try buildAssertion(privateKey: privateKey, scope: scope)

        var req = URLRequest(url: Self.tokenURL)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\(assertion)"
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw MaskinportenError.tokenFetchFailed(statusCode: http.statusCode, body: body)
        }

        struct TokenResponse: Decodable {
            let access_token: String
            let expires_in: Int
        }
        let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
        cached = (decoded.access_token, Date().addingTimeInterval(Double(decoded.expires_in)))
        return decoded.access_token
    }

    private func buildAssertion(privateKey: RSAKey, scope: String) throws -> String {
        let now = Int(Date().timeIntervalSince1970)
        var header: [String: Any] = ["alg": "RS256", "typ": "JWT"]
        if let kid = credentials.kid, !kid.isEmpty {
            header["kid"] = kid
        }
        let payload: [String: Any] = [
            "iss": credentials.clientId,
            "aud": Self.audience,
            "scope": scope,
            "iat": now,
            "exp": now + 120,
            "jti": UUID().uuidString,
        ]

        let headerB64  = try JSONSerialization.data(withJSONObject: header).base64url
        let payloadB64 = try JSONSerialization.data(withJSONObject: payload).base64url
        let signingInput = "\(headerB64).\(payloadB64)"

        let sig = try privateKey.signRS256(Data(signingInput.utf8))
        return "\(signingInput).\(sig.base64url)"
    }
}

public extension Data {
    var base64url: String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
