//
//  AuthScope.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

public enum AuthScope: Sendable, Equatable, Hashable {
    case openid
    case email
    case mobile
    case groups
    case profile
    case offlineAccess
    case custom(String)

    public var rawValue: String {
        switch self {
        case .openid: return "openid"
        case .email: return "email"
        case .mobile: return "mobile"
        case .groups: return "groups"
        case .profile: return "profile"
        case .offlineAccess: return "offline_access"
        case .custom(let value): return value
        }
    }

    public static let knownCases: [AuthScope] = [
        .openid, .email, .mobile, .groups, .profile, .offlineAccess
    ]
}

public extension Array where Element == AuthScope {
    static let mobileApp: [AuthScope] = [
        .openid, .email, .mobile, .groups, .profile, .offlineAccess
    ]

    static let documentation: [AuthScope] = [
        .openid, .offlineAccess, .profile, .email, .mobile
    ]

    var asSpaceSeparatedString: String {
        map(\.rawValue)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
