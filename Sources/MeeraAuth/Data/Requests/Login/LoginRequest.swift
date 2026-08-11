//
//  LoginRequest.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 06/08/2026.
//

import Foundation

enum LoginRequest: AuthRequest {
    case start
    case startMFA(sessionId: String)
    case flowHints(flowId: String, sessionId: String)
    case submit(
        flowId: String,
        option: LoginOption,
        identifier: String,
        password: String,
        method: String
    )
    case sendMFA(
        flowId: String,
        sessionId: String,
        channel: MFAChannel,
        resource: String,
        email: String?,
        mobile: String?,
        flowTokenId: String?
    )
    case verifyMFA(
        flowId: String,
        sessionId: String,
        channel: MFAChannel,
        code: String,
        flowTokenId: String,
        emailResource: String?
    )

    var path: String {
        switch self {
        case .start, .startMFA:
            return "login/api"
        case .flowHints:
            return "login/flows"
        case .submit, .sendMFA, .verifyMFA:
            return "login"
        }
    }

    var method: AuthRequestMethod {
        switch self {
        case .start, .startMFA, .flowHints:
            return .get
        case .submit, .sendMFA, .verifyMFA:
            return .post
        }
    }

    var query: [String: String] {
        switch self {
        case .startMFA:
            return ["aal": "aal2"]
        case .flowHints(let flowId, _):
            return ["id": flowId]
        case .submit(let flowId, _, _, _, _),
             .sendMFA(let flowId, _, _, _, _, _, _),
             .verifyMFA(let flowId, _, _, _, _, _):
            return ["flow": flowId]
        case .start:
            return [:]
        }
    }

    var sessionId: String? {
        switch self {
        case .startMFA(let sessionId),
             .flowHints(_, let sessionId),
             .sendMFA(_, let sessionId, _, _, _, _, _),
             .verifyMFA(_, let sessionId, _, _, _, _):
            return sessionId
        case .start, .submit:
            return nil
        }
    }

    var headers: [String: String] {
        switch self {
        case .submit, .sendMFA, .verifyMFA:
            return [
                "Content-Type": "application/json",
                "Accept": "application/json"
            ]
        default:
            return ["Accept": "application/json"]
        }
    }

    var body: AuthJSONObject? {
        switch self {
        case .start, .startMFA, .flowHints:
            return nil

        case let .submit(_, option, identifier, password, method):
            var body = Self.credentialBody(option: option, identifier: identifier, password: password)
            body["method"] = .string(method)
            return body

        case let .sendMFA(_, _, channel, resource, email, mobile, flowTokenId):
            var body: AuthJSONObject = [
                "method": .string(channel == .email ? "mfases" : "mfasms")
            ]
            switch channel {
            case .email:
                body["resource"] = .string(resource)
                if let email { body["email"] = .string(email) }
            case .sms:
                body["resource"] = .string(resource)
                if let mobile { body["mobile"] = .string(mobile) }
            }
            if let flowTokenId {
                body["flowTokenId"] = .string(flowTokenId)
            }
            return body

        case let .verifyMFA(_, _, channel, code, flowTokenId, emailResource):
            var body: AuthJSONObject = [
                "method": .string(channel == .email ? "mfases" : "mfasms"),
                "flowTokenId": .string(flowTokenId),
                "code": .string(code)
            ]
            if channel == .email, let emailResource {
                body["resource"] = .string(emailResource)
            }
            return body
        }
    }

    private static func credentialBody(
        option: LoginOption,
        identifier: String,
        password: String
    ) -> AuthJSONObject {
        switch option {
        case .email:
            return [
                "email": .string(identifier),
                "mobile": .string(""),
                "password": .string(password)
            ]
        case .phone:
            return [
                "email": .string(""),
                "mobile": .string(identifier),
                "password": .string(password)
            ]
        case .civilId:
            return [
                "civilId": .string(identifier),
                "password": .string(password)
            ]
        }
    }
}
