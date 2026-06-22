import CryptoKit
import Foundation

/// Hjelpere for å lage JWK fra en P-256-nøkkel, med stabil `kid` (RFC 7638-thumbprint).
public enum ECKeyJWK {

    /// Offentlig JWK klar for opplasting i Samarbeidsportalen, inkl. `kid`, `use` og `alg`.
    public static func publicJWK(for publicKey: P256.Signing.PublicKey) -> [String: Any] {
        let raw = Array(publicKey.rawRepresentation)  // 64 bytes: x(32) || y(32)
        let x = Data(raw[0..<32]).base64url
        let y = Data(raw[32..<64]).base64url
        return [
            "kty": "EC",
            "crv": "P-256",
            "x": x,
            "y": y,
            "kid": thumbprint(x: x, y: y),
            "use": "sig",
            "alg": "ES256",
        ]
    }

    /// RFC 7638-thumbprint brukt som `kid`. Deterministisk fra nøkkelen, så samme verdi
    /// kan regnes ut både ved opplasting og ved signering av token.
    public static func kid(for publicKey: P256.Signing.PublicKey) -> String {
        let raw = Array(publicKey.rawRepresentation)
        let x = Data(raw[0..<32]).base64url
        let y = Data(raw[32..<64]).base64url
        return thumbprint(x: x, y: y)
    }

    private static func thumbprint(x: String, y: String) -> String {
        // Medlemmene må være i leksikografisk rekkefølge og uten mellomrom (RFC 7638).
        let json = "{\"crv\":\"P-256\",\"kty\":\"EC\",\"x\":\"\(x)\",\"y\":\"\(y)\"}"
        return Data(SHA256.hash(data: Data(json.utf8))).base64url
    }
}
