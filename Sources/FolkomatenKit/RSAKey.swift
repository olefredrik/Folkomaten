import Foundation
import Security

/// En RSA-privatnøkkel lest fra PEM, klar til RS256-signering.
///
/// Samarbeidsportalen genererer nøkkelen i PKCS#8 (`BEGIN PRIVATE KEY`). `SecKeyCreateWithData`
/// forventer derimot PKCS#1 (`RSAPrivateKey`), så PKCS#8-innpakningen strippes først.
struct RSAKey {
    private let secKey: SecKey

    init(pem: String) throws {
        let der = try Self.derBytes(fromPEM: pem)
        let pkcs1 = try Self.pkcs1(fromPKCS8: der)

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
        ]
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(pkcs1 as CFData, attributes as CFDictionary, &error) else {
            throw MaskinportenError.invalidPrivateKey
        }
        self.secKey = key
    }

    func signRS256(_ data: Data) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let sig = SecKeyCreateSignature(
            secKey, .rsaSignatureMessagePKCS1v15SHA256, data as CFData, &error
        ) else {
            let detail = (error?.takeRetainedValue()).map { String(describing: $0) } ?? "ukjent feil"
            throw MaskinportenError.signingFailed(detail)
        }
        return sig as Data
    }

    // MARK: - PEM / DER

    private static func derBytes(fromPEM pem: String) throws -> Data {
        let base64 = pem
            .components(separatedBy: .newlines)
            .filter { !$0.hasPrefix("-----") }
            .joined()
        guard let der = Data(base64Encoded: base64) else {
            throw MaskinportenError.invalidPrivateKey
        }
        return der
    }

    /// Trekker ut PKCS#1-nøkkelen (OCTET STRING-innholdet) fra en PKCS#8 PrivateKeyInfo.
    /// Hvis input allerede er PKCS#1 (starter ikke som forventet PKCS#8), returneres den uendret.
    private static func pkcs1(fromPKCS8 der: Data) throws -> Data {
        let bytes = [UInt8](der)
        var i = 0

        func readLength() throws -> Int {
            guard i < bytes.count else { throw MaskinportenError.invalidPrivateKey }
            var len = Int(bytes[i]); i += 1
            if len & 0x80 != 0 {
                let count = len & 0x7f
                guard count > 0, i + count <= bytes.count else { throw MaskinportenError.invalidPrivateKey }
                len = 0
                for _ in 0..<count { len = (len << 8) | Int(bytes[i]); i += 1 }
            }
            return len
        }

        func expect(_ tag: UInt8) throws {
            guard i < bytes.count, bytes[i] == tag else { throw MaskinportenError.invalidPrivateKey }
            i += 1
        }

        do {
            try expect(0x30)            // SEQUENCE (PrivateKeyInfo)
            _ = try readLength()
            try expect(0x02)            // INTEGER version
            let vLen = try readLength(); i += vLen
            try expect(0x30)            // SEQUENCE (AlgorithmIdentifier)
            let aLen = try readLength(); i += aLen
            try expect(0x04)            // OCTET STRING (privateKey = PKCS#1)
            let oLen = try readLength()
            guard i + oLen <= bytes.count else { throw MaskinportenError.invalidPrivateKey }
            return Data(bytes[i..<(i + oLen)])
        } catch {
            // Kanskje allerede PKCS#1 – la SecKeyCreateWithData avgjøre.
            return der
        }
    }
}
