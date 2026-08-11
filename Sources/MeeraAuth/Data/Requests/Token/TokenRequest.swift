//
//  TokenRequest.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 06/08/2026.
//

import Foundation

enum TokenRequest: AuthRequest {
    case exchange(sessionId: String, clientId: String, scope: String)
    case refresh(clientId: String, refreshToken: String, scope: String?)

    var base: AuthAPIBase {
        switch self {
        case .exchange: return .ssoX
        case .refresh: return .sso
        }
    }

    var path: String {
        switch self {
        case .exchange: return "token/exchange"
        case .refresh: return "token"
        }
    }

    var method: AuthRequestMethod { .post }

    var bodyEncoding: AuthBodyEncoding { .formURLEncoded }

    var sessionId: String? {
        switch self {
        case .exchange(let sessionId, _, _): return sessionId
        case .refresh: return nil
        }
    }

    var headers: [String: String] {
        [
            "Content-Type": "application/x-www-form-urlencoded",
            "Accept": "application/json"
        ]
    }

    var body: AuthJSONObject? {
        switch self {
        case let .exchange(_, clientId, scope):
            return [
                "client_id": .string(clientId),
                "scope": .string(scope)
            ]
        case let .refresh(clientId, refreshToken, scope):
            var form: AuthJSONObject = [
                "grant_type": .string("refresh_token"),
                "refresh_token": .string(refreshToken),
                "client_id": .string(clientId)
            ]
            if let scope, !scope.isEmpty {
                form["scope"] = .string(scope)
            }
            return form
        }
    }
}
