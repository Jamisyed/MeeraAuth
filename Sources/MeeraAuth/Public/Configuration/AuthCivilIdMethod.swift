//
//  AuthCivilIdMethod.swift
//  MeeraAuth
//

import Foundation

/// SSO App Client `method` value for Civil ID login, registration, and settings.
/// Host configures once; public APIs still use `LoginOption.civilId` / signup Civil ID.
public enum AuthCivilIdMethod: Sendable, Hashable {
    case civilid
    case mafwrInternal
    case custom(String)

    public var rawValue: String {
        switch self {
        case .civilid: return "civilid"
        case .mafwrInternal: return "mafwrInternal"
        case .custom(let value): return value
        }
    }
}
