import Foundation
import Security

public enum KeychainCredentials {
    private static let service     = "no.justify.testborger"
    private static let clientIdKey = "maskinporten-client-id"
    private static let privateKey  = "maskinporten-private-key-pem"

    public static var clientId: String? {
        get { load(clientIdKey) }
        set { newValue.map { save($0, key: clientIdKey) } ?? delete(clientIdKey) }
    }

    public static var privateKeyPEM: String? {
        get { load(privateKey) }
        set { newValue.map { save($0, key: privateKey) } ?? delete(privateKey) }
    }

    public static var isConfigured: Bool {
        clientId != nil && privateKeyPEM != nil
    }

    public static func credentials() -> MaskinportenCredentials? {
        guard let id = clientId, let pem = privateKeyPEM else { return nil }
        return MaskinportenCredentials(clientId: id, privateKeyPEM: pem)
    }

    // MARK: - Privat

    private static func save(_ value: String, key: String) {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String:   Data(value.utf8),
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private static func load(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
