//
//  LogoutRequest.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 06/08/2026.
//

import Foundation

enum LogoutRequest: AuthRequest {
    case logout(accessToken: String)

    var base: AuthAPIBase { .sso }

    var path: String { "logout/api" }

    var method: AuthRequestMethod { .delete }

    var bearerToken: String? {
        switch self {
        case .logout(let accessToken): return accessToken
        }
    }

    var headers: [String: String] {
        ["Accept": "application/json"]
    }
}
