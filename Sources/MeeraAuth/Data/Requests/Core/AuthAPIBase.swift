//
//  AuthAPIBase.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 06/08/2026.
//

import Foundation

/// Which SSO root the request targets.
enum AuthAPIBase: Sendable {
    /// `config.ssoXEndpoint` — login / registration / recovery / settings / verification / token exchange.
    case ssoX
    /// `config.ssoEndpoint` — OAuth token refresh, logout.
    case sso

    func url(from config: AuthConfiguration) -> URL {
        switch self {
        case .ssoX: return config.ssoXEndpoint
        case .sso: return config.ssoEndpoint
        }
    }
}
