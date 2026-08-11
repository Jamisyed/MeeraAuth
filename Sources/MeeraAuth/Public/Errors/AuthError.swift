//
//  AuthError.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

public enum AuthField: String, Sendable, Equatable {
    case email
    case phone
    case password
    case civilId
    case otp
    case general
}

public enum AuthErrorCode: Int, Sendable, Equatable, CaseIterable {
    case success = 2000
    case badRequest = 4000
    case invalidArguments = 4001
    case unauthorized = 4002
    case forbidden = 4003
    case notFound = 4004
    case `internal` = 5000
    case noActiveSession = 6001
    case alreadyLoggedIn = 6002
    case flowExpired = 6003
    case strategyNotResponsible = 6004
    case completedByStrategy = 6005
    case noStrategyResponsible = 6006
    case invalidCSRFNotSent = 6007
    case invalidCSRFMismatch = 6008
    case originNeedsBrowser = 6009
    case cookieNeedsBrowser = 6010
    case aalNotSatisfied = 6013
    case registrationDisabled = 6014
    case verificationDisabled = 6018
    case settingsDisabled = 6019
    case recoveryDisabled = 6020
    case tokenExpired = 6028
    case needsReAuth = 6029
    case sessionRequiredForHigherAAL = 6030
    case continuityExpired = 6032
    case apiFlowNotSupported = 6033
    case securityIdentityMismatch = 6046
    case identityAlreadyExists = 6047
    case identityHasVerified = 6048
    case identityConflict = 6049
    case identityNotFound = 6050
    case passwordMismatch = 6051
    case passwordBeenUsed = 6052
    case passwordLocked = 6053
    case passwordExpired = 6054
    case invalidPassword = 6055
    case invalidPasswordSize = 6056
    case emailNotVerified = 6057
    case mobileNotVerified = 6058
    case identityLocked = 6059
    case emailDuplicate = 6060
    case mobileDuplicate = 6061
    case codeHasSend = 6062
    case codeHasResend = 6063
    case codeMismatch = 6064
    case codeCompleted = 6065
    case codeExpired = 6066
    case unableResource = 6067
    case codeSendFrequently = 6070
    case codeVerifyReachMaximum = 6071
    case imageCaptchaMismatch = 6074
    case accessLimitFrequently = 6075
    case reflushByStrategy = 6076
    case invalidCivilID = 6077
    case civilIDExpiryDateMismatch = 6078
    case civilIDMobileNotChanged = 6079
    case civilIDNotFound = 6080
    case onlyLoginCivilID = 6081
    case invalidCivilIDCRN = 6082
    case notAllowedCivilIDCRN = 6083
    case identityNotSync = 6084
    case civilIDNonOmani = 6090
    case unknown = 9000
    case network = -1
    case decoding = -2
    case methodDisabled = -3
    case invalidState = -4
    case serviceUnavailable = -5

    static func fromHTTPStatus(_ status: Int?) -> AuthErrorCode {
        guard let status else { return .network }
        switch status {
        case 400:
            return .unknown
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 408:
            return .serviceUnavailable
        case 422:
            return .invalidArguments
        case 429:
            return .accessLimitFrequently
        case 401...499:
            return .badRequest
        case 500...599:
            return .serviceUnavailable
        default:
            return .network
        }
    }
}

public struct AuthError: Error, Sendable, Equatable {
    public let code: AuthErrorCode
    public let message: String
    public let httpStatus: Int?
    public let field: AuthField?
    public let context: [String: String]
    public let rawCode: Int?

    public var retryable: Bool {
        switch code {
        case .network, .serviceUnavailable, .codeSendFrequently, .accessLimitFrequently, .reflushByStrategy, .flowExpired:
            return true
        default:
            return false
        }
    }

    public var isInformationalOTP: Bool {
        code == .codeHasSend || code == .codeHasResend
    }

    public init(
        code: AuthErrorCode,
        message: String,
        httpStatus: Int? = nil,
        field: AuthField? = nil,
        context: [String: String] = [:],
        rawCode: Int? = nil
    ) {
        self.code = code
        self.message = message
        self.httpStatus = httpStatus
        self.field = field
        self.context = context
        self.rawCode = rawCode ?? code.rawValue
    }

    public static func methodDisabled(
        _ option: LoginOption,
        enabled: Set<LoginOption>
    ) -> AuthError {
        let allowed = enabled.map(\.rawValue).sorted().joined(separator: ", ")
        let enabledDisplay = allowed.isEmpty ? "none" : allowed
        return AuthError(
            code: .methodDisabled,
            message: "Unsupported login method '\(option.rawValue)'. It is not in AuthConfiguration.loginOptions (enabled: \(enabledDisplay)). Client allow-list — SSO was not called. Add .\(option.rawValue) in host bootstrap to enable.",
            field: .general,
            context: [
                "option": option.rawValue,
                "enabled": enabledDisplay,
                "fault": "host.loginOptions",
                "ssoContacted": "false"
            ]
        )
    }

    public static func signupMethodDisabled(
        _ option: SignupOption,
        enabled: Set<SignupOption>
    ) -> AuthError {
        let allowed = enabled.map(\.rawValue).sorted().joined(separator: ", ")
        let enabledDisplay = allowed.isEmpty ? "none" : allowed
        return AuthError(
            code: .methodDisabled,
            message: "Unsupported signup method '\(option.rawValue)'. It is not in AuthConfiguration.signupOptions (enabled: \(enabledDisplay)). Client allow-list — SSO was not called. Add .\(option.rawValue) in host bootstrap to enable.",
            field: .general,
            context: [
                "option": option.rawValue,
                "enabled": enabledDisplay,
                "fault": "host.signupOptions",
                "ssoContacted": "false"
            ]
        )
    }

    public static func signupDisabled() -> AuthError {
        AuthError(
            code: .methodDisabled,
            message: "Signup is disabled. AuthConfiguration.signupOptions is empty — SSO was not called.",
            field: .general,
            context: [
                "enabled": "none",
                "fault": "host.signupOptions",
                "ssoContacted": "false"
            ]
        )
    }

    public static func network(_ message: String, status: Int? = nil) -> AuthError {
        AuthError(
            code: AuthErrorCode.fromHTTPStatus(status),
            message: message,
            httpStatus: status
        )
    }
}

enum ErrorMapper {
    static func code(from raw: Int) -> AuthErrorCode {
        AuthErrorCode(rawValue: raw) ?? .unknown
    }

    static func field(for code: AuthErrorCode) -> AuthField {
        switch code {
        case .passwordMismatch, .passwordBeenUsed, .passwordLocked, .passwordExpired,
             .invalidPassword, .invalidPasswordSize:
            return .password
        case .codeMismatch, .codeExpired, .codeVerifyReachMaximum, .codeSendFrequently,
             .codeHasSend, .codeHasResend, .codeCompleted:
            return .otp
        case .invalidCivilID, .civilIDExpiryDateMismatch, .civilIDNotFound,
             .onlyLoginCivilID, .invalidCivilIDCRN, .notAllowedCivilIDCRN,
             .civilIDMobileNotChanged, .civilIDNonOmani:
            return .civilId
        case .emailNotVerified, .emailDuplicate:
            return .email
        case .identityAlreadyExists:
            return .email
        case .mobileNotVerified, .mobileDuplicate:
            return .phone
        case .registrationDisabled:
            return .general
        default:
            return .general
        }
    }

    static func field(for code: AuthErrorCode, message: String) -> AuthField {
        if code == .identityAlreadyExists {
            let text = message.lowercased()
            if text.contains("civilid") || text.contains("civil id") {
                return .civilId
            }
            if text.contains("mobile") || text.contains("phone") {
                return .phone
            }
            if text.contains("email") {
                return .email
            }
        }
        return field(for: code)
    }

    static func fromFlowMessages(_ messages: [FlowMessage], httpStatus: Int? = nil) -> AuthError? {
        // Trust SSO `type`: only `"error"` becomes AuthError. `"info"` / `"success"` stay as notices.
        let errors = messages.filter { ($0.type ?? "").lowercased() == "error" }
        guard let candidate = errors.first, let raw = candidate.code else { return nil }
        let mapped = code(from: raw)
        if mapped == .codeHasSend || mapped == .codeHasResend { return nil }
        var ctx: [String: String] = [:]
        if let expired = candidate.context?["expired_at"] { ctx["expired_at"] = expired }
        return AuthError(
            code: mapped,
            message: candidate.text,
            httpStatus: httpStatus,
            field: field(for: mapped, message: candidate.text),
            context: ctx,
            rawCode: raw
        )
    }
}
