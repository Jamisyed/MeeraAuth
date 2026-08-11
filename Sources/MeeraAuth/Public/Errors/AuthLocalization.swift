//
//  AuthLocalization.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 07/08/2026.
//

import Foundation

public enum AuthLocalization: Sendable {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var _locale: AuthLocale = .english
    nonisolated(unsafe) private static var catalog: [String: [String: String]]?

    public static var locale: AuthLocale {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _locale
        }
        set {
            lock.lock()
            _locale = newValue
            lock.unlock()
        }
    }

    public static func string(forKey key: String, locale: AuthLocale? = nil) -> String {
        let resolved = locale ?? Self.locale
        let table = loadCatalog()
        if let value = table[key]?[resolved.rawValue], !value.isEmpty {
            return value
        }
        if let value = table[key]?[AuthLocale.english.rawValue], !value.isEmpty {
            return value
        }
        if let value = table["auth.error.generic"]?[resolved.rawValue], !value.isEmpty {
            return value
        }
        if let value = table["auth.error.generic"]?[AuthLocale.english.rawValue], !value.isEmpty {
            return value
        }
        return key
    }

    private static func loadCatalog() -> [String: [String: String]] {
        lock.lock()
        defer { lock.unlock() }
        if let catalog {
            return catalog
        }
        let loaded = parseCatalog()
        catalog = loaded
        return loaded
    }

    private static func parseCatalog() -> [String: [String: String]] {
        guard let jsonURL = Bundle.module.url(forResource: "AuthErrorCatalog", withExtension: "json"),
              let data = try? Data(contentsOf: jsonURL),
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: [String: String]],
              !parsed.isEmpty
        else {
            return [:]
        }
        return parsed
    }
}
