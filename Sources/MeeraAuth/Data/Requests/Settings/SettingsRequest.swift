//
//  SettingsRequest.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 06/08/2026.
//

import Foundation

enum SettingsRequest: AuthRequest {
    case start(sessionId: String?, accessToken: String?)
    case verifyCivilId(flowId: String, sessionId: String, civilId: String, expiry: String, method: String)
    case sendMobileCode(
        flowId: String,
        sessionId: String,
        mobile: String,
        resource: String,
        username: String?,
        civilIdUpdate: Bool,
        useCivilIDMobile: Bool,
        method: String
    )
    case verifyMobileCode(flowId: String, sessionId: String, flowTokenId: String, code: String, method: String)
    case sendEmailCode(flowId: String, sessionId: String, email: String, resource: String, method: String)
    case verifyEmailCode(flowId: String, sessionId: String, flowTokenId: String, code: String, method: String)
    case confirmBindCivilId(flowId: String, sessionId: String, method: String)
    case updatePassword(flowId: String, sessionId: String, password: String, confirmPassword: String)

    var path: String {
        switch self {
        case .start: return "settings/api"
        default: return "settings"
        }
    }

    var method: AuthRequestMethod {
        switch self {
        case .start: return .get
        default: return .post
        }
    }

    var query: [String: String] {
        switch self {
        case .start:
            return [:]
        case .verifyCivilId(let flowId, _, _, _, _),
             .sendMobileCode(let flowId, _, _, _, _, _, _, _),
             .verifyMobileCode(let flowId, _, _, _, _),
             .sendEmailCode(let flowId, _, _, _, _),
             .verifyEmailCode(let flowId, _, _, _, _),
             .confirmBindCivilId(let flowId, _, _),
             .updatePassword(let flowId, _, _, _):
            return ["flow": flowId]
        }
    }

    var sessionId: String? {
        switch self {
        case .start(let sessionId, _):
            return sessionId
        case .verifyCivilId(_, let sessionId, _, _, _),
             .sendMobileCode(_, let sessionId, _, _, _, _, _, _),
             .verifyMobileCode(_, let sessionId, _, _, _),
             .sendEmailCode(_, let sessionId, _, _, _),
             .verifyEmailCode(_, let sessionId, _, _, _),
             .confirmBindCivilId(_, let sessionId, _),
             .updatePassword(_, let sessionId, _, _):
            return sessionId
        }
    }

    var bearerToken: String? {
        switch self {
        case .start(_, let accessToken):
            return accessToken
        default:
            return nil
        }
    }

    var headers: [String: String] {
        switch self {
        case .start:
            return ["Accept": "application/json"]
        default:
            return [
                "Content-Type": "application/json",
                "Accept": "application/json"
            ]
        }
    }

    var body: AuthJSONObject? {
        switch self {
        case .start:
            return nil

        case let .verifyCivilId(_, _, civilId, expiry, method):
            return [
                "method": .string(method),
                "civilId": .string(civilId),
                "civilIdExpiry": .string(expiry)
            ]

        case let .sendMobileCode(_, _, mobile, resource, username, civilIdUpdate, useCivilIDMobile, method):
            var body: AuthJSONObject = [
                "mobile": .string(mobile),
                "resource": .string(resource),
                "civilIdUpdate": .bool(civilIdUpdate),
                "useCivilIDMobile": .bool(useCivilIDMobile),
                "method": .string(method)
            ]
            if let username { body["username"] = .string(username) }
            return body

        case let .verifyMobileCode(_, _, flowTokenId, code, method),
             let .verifyEmailCode(_, _, flowTokenId, code, method):
            return [
                "code": .string(code),
                "flowTokenId": .string(flowTokenId),
                "method": .string(method)
            ]

        case let .sendEmailCode(_, _, email, resource, method):
            return [
                "email": .string(email),
                "resource": .string(resource),
                "method": .string(method)
            ]

        case let .confirmBindCivilId(_, _, method):
            return ["method": .string(method)]

        case let .updatePassword(_, _, password, confirmPassword):
            return [
                "method": .string("password"),
                "password": .string(password),
                "confirmPassword": .string(confirmPassword)
            ]
        }
    }
}
