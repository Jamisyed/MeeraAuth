//
//  AuthFlowNotice.swift
//  MeeraAuth
//

import Foundation

public struct AuthFlowNotice: Sendable, Equatable {
    public let code: AuthErrorCode
    public let rawCode: Int?
    public let serverText: String
    public let context: [String: String]

    public init(
        code: AuthErrorCode,
        rawCode: Int? = nil,
        serverText: String = "",
        context: [String: String] = [:]
    ) {
        self.code = code
        self.rawCode = rawCode
        self.serverText = serverText
        self.context = context
    }

    public var localizationKey: String {
        code.infoLocalizationKey
    }

    public func localizedDescription(for locale: AuthLocale? = nil) -> String {
        let message = AuthLocalization.string(forKey: localizationKey, locale: locale)
        guard AuthNetworkLogging.current.includesErrorCode else {
            return message
        }
        return "\(message) (\(rawCode ?? code.rawValue))"
    }

    public var localizedDescription: String {
        localizedDescription(for: nil)
    }

    static func notices(from messages: [FlowMessage]) -> [AuthFlowNotice] {
        messages.compactMap { message in
            guard let raw = message.code else { return nil }
            let type = (message.type ?? "").lowercased()
            let mapped = AuthErrorCode(rawValue: raw)
            let isInfoType = type == "info" || type == "success"

            if type == "error" {
                guard let mapped, mapped.isInformationalNotice else { return nil }
            } else if !isInfoType {
                guard let mapped, mapped.isInformationalNotice else { return nil }
            }

            return AuthFlowNotice(
                code: mapped ?? .success,
                rawCode: raw,
                serverText: message.text,
                context: message.context ?? [:]
            )
        }
    }
}

extension AuthErrorCode {
    public var isInformationalNotice: Bool {
        switch self {
        case .success, .codeHasSend, .codeHasResend, .codeCompleted, .identityHasVerified:
            return true
        default:
            return false
        }
    }

    public var infoLocalizationKey: String {
        switch self {
        case .success:
            return "auth.info.success"
        case .codeHasSend:
            return "auth.info.code_sent"
        case .codeHasResend:
            return "auth.info.code_resent"
        case .codeCompleted:
            return "auth.info.code_completed"
        case .identityHasVerified:
            return "auth.info.identity_verified"
        default:
            return "auth.info.generic"
        }
    }
}
