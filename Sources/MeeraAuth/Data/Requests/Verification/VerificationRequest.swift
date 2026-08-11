//
//  VerificationRequest.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 06/08/2026.
//

import Foundation

enum VerificationRequest: AuthRequest {
    case start
    case sendOTP(flowId: String, channel: MFAChannel, identifier: String, resource: String)
    case resendOTP(flowId: String, body: AuthJSONObject)
    case verifyOTP(flowId: String, body: AuthJSONObject)

    var path: String {
        switch self {
        case .start: return "verification/api"
        case .sendOTP, .resendOTP, .verifyOTP: return "verification"
        }
    }

    var method: AuthRequestMethod {
        switch self {
        case .start: return .get
        case .sendOTP, .resendOTP, .verifyOTP: return .post
        }
    }

    var query: [String: String] {
        switch self {
        case .sendOTP(let flowId, _, _, _),
             .resendOTP(let flowId, _),
             .verifyOTP(let flowId, _):
            return ["flow": flowId]
        case .start:
            return [:]
        }
    }

    var headers: [String: String] {
        switch self {
        case .sendOTP, .resendOTP, .verifyOTP:
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
        case let .sendOTP(_, channel, identifier, resource):
            var body: AuthJSONObject = [
                "method": .string("captcha"),
                "resource": .string(resource)
            ]
            switch channel {
            case .email: body["email"] = .string(identifier)
            case .sms: body["mobile"] = .string(identifier)
            }
            return body
        case .resendOTP(_, let body), .verifyOTP(_, let body):
            return body
        }
    }
}
