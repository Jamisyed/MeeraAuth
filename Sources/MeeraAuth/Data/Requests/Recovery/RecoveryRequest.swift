//
//  RecoveryRequest.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 06/08/2026.
//

import Foundation

enum RecoveryRequest: AuthRequest {
    case start
    case sendCode(
        flowId: String,
        option: LoginOption,
        identifier: String,
        resource: String
    )
    case resendCode(flowId: String, body: AuthJSONObject)
    case verifyCode(flowId: String, flowTokenId: String, code: String)

    var path: String {
        switch self {
        case .start: return "recovery/api"
        case .sendCode, .resendCode, .verifyCode: return "recovery"
        }
    }

    var method: AuthRequestMethod {
        switch self {
        case .start: return .get
        case .sendCode, .resendCode, .verifyCode: return .post
        }
    }

    var query: [String: String] {
        switch self {
        case .sendCode(let flowId, _, _, _),
             .resendCode(let flowId, _),
             .verifyCode(let flowId, _, _):
            return ["flow": flowId]
        case .start:
            return [:]
        }
    }

    var headers: [String: String] {
        switch self {
        case .sendCode, .resendCode, .verifyCode:
            return [
                "Content-Type": "application/json",
                "Accept": "application/json"
            ]
        case .start:
            return ["Accept": "application/json"]
        }
    }

    var body: AuthJSONObject? {
        switch self {
        case .start:
            return nil

        case let .sendCode(_, option, identifier, resource):
            var body: AuthJSONObject = [
                "method": .string("captcha"),
                "email": .string(""),
                "mobile": .string(""),
                "civilid": .string(""),
                "resource": .string(resource)
            ]
            switch option {
            case .email: body["email"] = .string(identifier)
            case .phone: body["mobile"] = .string(identifier)
            case .civilId: body["civilid"] = .string(identifier)
            }
            return body

        case .resendCode(_, let body):
            return body

        case let .verifyCode(_, flowTokenId, code):
            return [
                "code": .string(code),
                "flowTokenId": .string(flowTokenId),
                "method": .string("captcha")
            ]
        }
    }
}
