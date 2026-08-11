//
//  RegistrationRequest.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 06/08/2026.
//

import Foundation

enum RegistrationRequest: AuthRequest {
    case start
    case submitPassword(flowId: String, profile: RegistrationProfile, resource: String)
    case verifyCivilId(flowId: String, civilId: String, expiry: String, method: String)
    case sendMobileOTP(
        flowId: String,
        mobile: String,
        username: String?,
        resource: String,
        useCivilIDMobile: Bool,
        flowTokenId: String?,
        method: String
    )
    case verifyOTP(flowId: String, code: String, flowTokenId: String, method: String, resource: String)
    case sendEmailOTP(flowId: String, email: String, resource: String, flowTokenId: String?, method: String)
    case submitCivilIdPassword(flowId: String, password: String, confirmPassword: String, method: String)

    var path: String {
        switch self {
        case .start: return "registration/api"
        default: return "registration"
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
        case .submitPassword(let flowId, _, _),
             .verifyCivilId(let flowId, _, _, _),
             .sendMobileOTP(let flowId, _, _, _, _, _, _),
             .verifyOTP(let flowId, _, _, _, _),
             .sendEmailOTP(let flowId, _, _, _, _),
             .submitCivilIdPassword(let flowId, _, _, _):
            return ["flow": flowId]
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

        case let .submitPassword(_, profile, resource):
            return [
                "email": .string(profile.email),
                "mobile": .string(profile.mobile),
                "username": .string(profile.username),
                "firstname": .string(profile.firstName),
                "middlename": .string(profile.middleName),
                "lastname": .string(profile.lastName),
                "password": .string(profile.password),
                "confirmPassword": .string(profile.confirmPassword),
                "resource": .string(resource),
                "method": .string("password")
            ]

        case let .verifyCivilId(_, civilId, expiry, method):
            return [
                "method": .string(method),
                "civilId": .string(civilId),
                "civilIdExpiry": .string(expiry)
            ]

        case let .sendMobileOTP(_, mobile, username, resource, useCivilIDMobile, flowTokenId, method):
            var body: AuthJSONObject = [
                "mobile": .string(mobile),
                "resource": .string(resource),
                "useCivilIDMobile": .bool(useCivilIDMobile),
                "method": .string(method)
            ]
            if let username { body["username"] = .string(username) }
            if let flowTokenId { body["flowTokenId"] = .string(flowTokenId) }
            return body

        case let .verifyOTP(_, code, flowTokenId, method, resource):
            return [
                "code": .string(code),
                "flowTokenId": .string(flowTokenId),
                "method": .string(method),
                "resource": .string(resource)
            ]

        case let .sendEmailOTP(_, email, resource, flowTokenId, method):
            var body: AuthJSONObject = [
                "email": .string(email),
                "resource": .string(resource),
                "method": .string(method)
            ]
            if let flowTokenId { body["flowTokenId"] = .string(flowTokenId) }
            return body

        case let .submitCivilIdPassword(_, password, confirmPassword, method):
            return [
                "password": .string(password),
                "confirmPassword": .string(confirmPassword),
                "method": .string(method)
            ]
        }
    }
}
