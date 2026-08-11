//
//  KeychainTokenStore.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation
#if canImport(Security)
import Security
#endif

/// Keychain-backed token store for production hosts.
/// Default Keychain `service` is derived from `Bundle.main.bundleIdentifier`.
public actor KeychainTokenStore: TokenStore {
    private let service: String
    private let account: String

    public init(
        service: String = KeychainTokenStore.defaultService,
        account: String = KeychainTokenStore.defaultAccount
    ) {
        self.service = service
        self.account = account
    }

    /// `{bundleId}.auth.tokens` — unique per host app.
    public static var defaultService: String {
        if let bundleId = Bundle.main.bundleIdentifier, !bundleId.isEmpty {
            return "\(bundleId).auth.tokens"
        }
        return "MeeraAuth.auth.tokens"
    }

    public static let defaultAccount = "tokens"

    public func load() async throws -> TokenSet? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return try JSONDecoder().decode(TokenSet.self, from: data)
    }

    public func save(_ tokens: TokenSet) async throws {
        let data = try JSONEncoder().encode(tokens)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(add as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AuthError(code: .internal, message: "Keychain save failed (\(status))")
        }
    }

    public func clear() async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
