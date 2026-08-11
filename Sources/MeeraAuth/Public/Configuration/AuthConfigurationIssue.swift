//
//  AuthConfigurationIssue.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

public enum AuthConfigurationIssue: Sendable, Equatable, CustomStringConvertible {
    case missingClientId
    case missingScopes
    case missingLoginOptions
    case invalidSSOEndpoint(URL)
    case invalidSSOXEndpoint(URL)
    case emptyResourceTemplate(String)

    public var message: String {
        switch self {
        case .missingClientId:
            return "clientId is required (e.g. AuthClientID.mobileApp)"
        case .missingScopes:
            return "scopes must not be empty (e.g. [.openid, .email, .profile, .offlineAccess])"
        case .missingLoginOptions:
            return "loginOptions must not be empty (enable at least one of .email / .phone / .civilId)"
        case .invalidSSOEndpoint(let url):
            return "ssoEndpoint is invalid: \(url.absoluteString) (expect https host)"
        case .invalidSSOXEndpoint(let url):
            return "ssoXEndpoint is invalid: \(url.absoluteString) (expect https …/x host)"
        case .emptyResourceTemplate(let name):
            return "resources.\(name) must not be empty"
        }
    }

    public var description: String { message }
}
