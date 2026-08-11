//
//  AuthClientID.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

public enum AuthClientID: Sendable, Equatable, Hashable {
    case mobileApp
    case meeraApps
    case custom(String)

    public var rawValue: String {
        switch self {
        case .mobileApp: return "mobile-app"
        case .meeraApps: return "meera-apps"
        case .custom(let value): return value
        }
    }

    public static let knownCases: [AuthClientID] = [
        .mobileApp, .meeraApps
    ]
}
