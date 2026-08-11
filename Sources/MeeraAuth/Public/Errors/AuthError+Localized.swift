//
//  AuthError+Localized.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 07/08/2026.
//

import Foundation

extension AuthError: LocalizedError {
    public var errorDescription: String? {
        userFacingMessage()
    }

    public func localizedDescription(for locale: AuthLocale) -> String {
        userFacingMessage(locale: locale)
    }

    public func userFacingMessage(locale: AuthLocale? = nil) -> String {
        let message = code.localizedUserMessage(locale: locale)
        guard AuthNetworkLogging.current.includesErrorCode else {
            return message
        }
        return "\(message) (\(rawCode ?? code.rawValue))"
    }
}

extension AuthErrorCode {
    public var localizationKey: String {
        switch self {
        case .flowExpired:
            return "auth.error.flow_expired"
        case .identityAlreadyExists:
            return "auth.error.identity_already_exists"
        case .identityNotFound:
            return "auth.error.identity_not_found"
        case .identityConflict:
            return "auth.error.identity_conflict"
        case .passwordMismatch:
            return "auth.error.password_mismatch"
        case .passwordBeenUsed:
            return "auth.error.password_been_used"
        case .passwordLocked:
            return "auth.error.password_locked"
        case .passwordExpired:
            return "auth.error.password_expired"
        case .invalidPassword, .invalidPasswordSize:
            return "auth.error.invalid_password"
        case .emailDuplicate:
            return "auth.error.email_duplicate"
        case .mobileDuplicate:
            return "auth.error.mobile_duplicate"
        case .emailNotVerified:
            return "auth.error.email_not_verified"
        case .mobileNotVerified:
            return "auth.error.mobile_not_verified"
        case .codeMismatch:
            return "auth.error.code_mismatch"
        case .codeExpired:
            return "auth.error.code_expired"
        case .codeSendFrequently:
            return "auth.error.code_send_frequently"
        case .codeVerifyReachMaximum:
            return "auth.error.code_verify_max"
        case .invalidCivilID:
            return "auth.error.invalid_civil_id"
        case .civilIDExpiryDateMismatch:
            return "auth.error.civil_id_expiry_mismatch"
        case .civilIDNotFound:
            return "auth.error.civil_id_not_found"
        case .civilIDNonOmani:
            return "auth.error.civil_id_non_omani"
        case .onlyLoginCivilID:
            return "auth.error.only_login_civil_id"
        case .registrationDisabled:
            return "auth.error.registration_disabled"
        case .badRequest, .invalidArguments:
            return "auth.error.bad_request"
        case .notFound:
            return "auth.error.not_found"
        case .network:
            return "auth.error.network"
        case .serviceUnavailable:
            return "auth.error.service_unavailable"
        case .methodDisabled:
            return "auth.error.method_disabled"
        case .invalidState:
            return "auth.error.invalid_state"
        case .unauthorized, .forbidden:
            return "auth.error.unauthorized"
        case .noActiveSession:
            return "auth.error.no_active_session"
        case .tokenExpired, .needsReAuth:
            return "auth.error.session_expired"
        case .identityLocked:
            return "auth.error.identity_locked"
        case .identityNotSync:
            return "auth.error.identity_not_sync"
        case .accessLimitFrequently:
            return "auth.error.access_limit"
        default:
            return "auth.error.generic"
        }
    }

    public func localizedUserMessage(locale: AuthLocale? = nil) -> String {
        AuthLocalization.string(forKey: localizationKey, locale: locale)
    }

    public var localizedUserMessage: String {
        localizedUserMessage(locale: nil)
    }
}
