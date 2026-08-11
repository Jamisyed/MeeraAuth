//
//  AuthClient+Settings.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 06/08/2026.
//

import Foundation

extension AuthClient {
    // MARK: - Settings (Civil ID)

    public func startSettings() async throws {
        let sessionId = try await sessionStore.load()?.id
        let token = try await tokenStore.load()?.accessToken
        try await settingsFlow.start(sessionId: sessionId, accessToken: token)
    }

    @discardableResult
    public func settingsVerifyCivilId(_ civilId: String, expiry: String) async throws -> CivilIdVerificationResult {
        guard let sessionId = try await sessionStore.load()?.id else {
            throw AuthError(code: .noActiveSession, message: "Settings require a session")
        }
        return try await settingsFlow.verifyCivilId(sessionId: sessionId, civilId: civilId, expiry: expiry)
    }

    @discardableResult
    public func settingsSendMobileCode(
        mobile: String,
        username: String? = nil,
        civilIdUpdate: Bool = true,
        useCivilIDMobile: Bool = true
    ) async throws -> [AuthFlowNotice] {
        guard let sessionId = try await sessionStore.load()?.id else {
            throw AuthError(code: .noActiveSession, message: "Settings require a session")
        }
        return try await settingsFlow.sendMobileCode(
            sessionId: sessionId,
            mobile: mobile,
            username: username,
            civilIdUpdate: civilIdUpdate,
            useCivilIDMobile: useCivilIDMobile
        )
    }

    @discardableResult
    public func settingsVerifyMobileCode(_ code: String) async throws -> [AuthFlowNotice] {
        guard let sessionId = try await sessionStore.load()?.id else {
            throw AuthError(code: .noActiveSession, message: "Settings require a session")
        }
        return try await settingsFlow.verifyMobileCode(sessionId: sessionId, code: code)
    }

    @discardableResult
    public func settingsSendEmailCode(_ email: String) async throws -> [AuthFlowNotice] {
        guard let sessionId = try await sessionStore.load()?.id else {
            throw AuthError(code: .noActiveSession, message: "Settings require a session")
        }
        return try await settingsFlow.sendEmailCode(sessionId: sessionId, email: email)
    }

    @discardableResult
    public func settingsVerifyEmailCode(_ code: String) async throws -> [AuthFlowNotice] {
        guard let sessionId = try await sessionStore.load()?.id else {
            throw AuthError(code: .noActiveSession, message: "Settings require a session")
        }
        return try await settingsFlow.verifyEmailCode(sessionId: sessionId, code: code)
    }

    @discardableResult
    public func settingsConfirmBindCivilId() async throws -> [AuthFlowNotice] {
        guard let sessionId = try await sessionStore.load()?.id else {
            throw AuthError(code: .noActiveSession, message: "Settings require a session")
        }
        return try await settingsFlow.confirmBindCivilId(sessionId: sessionId)
    }

    @discardableResult
    public func settingsUpdatePassword(password: String, confirmPassword: String) async throws -> [AuthFlowNotice] {
        guard let sessionId = try await sessionStore.load()?.id else {
            throw AuthError(code: .noActiveSession, message: "Settings require a session")
        }
        return try await settingsFlow.updatePassword(
            sessionId: sessionId,
            password: password,
            confirmPassword: confirmPassword
        )
    }
}
