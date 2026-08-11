//
//  AuthClient+Login.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 06/08/2026.
//

import Foundation

extension AuthClient {
    // MARK: - Login

    public func startLogin() async throws {
        try await loginFlow.start()
    }

    public func login(
        option: LoginOption,
        identifier: String,
        password: String
    ) async throws -> LoginStep {
        let step = try await loginFlow.submit(
            option: option,
            identifier: identifier,
            password: password
        )
        switch step {
        case .authenticated(let session, _):
            try await sessionStore.save(session)
            emit(.sessionUpdated(session))
        case .requiresMFA(_, let sessionId, _):
            try await sessionStore.save(Session(id: sessionId, identity: nil))
        }
        return step
    }

    @discardableResult
    public func sendLoginMFA() async throws -> [AuthFlowNotice] {
        guard let session = try await sessionStore.load() else {
            throw AuthError(code: .noActiveSession, message: "No session for MFA")
        }
        if await biometricFlow.isMFAActive() {
            return try await biometricFlow.sendMFA(sessionId: session.id)
        }
        return try await loginFlow.sendMFA(sessionId: session.id)
    }

    @discardableResult
    public func resendLoginMFA() async throws -> [AuthFlowNotice] {
        guard let session = try await sessionStore.load() else {
            throw AuthError(code: .noActiveSession, message: "No session for MFA")
        }
        if await biometricFlow.isMFAActive() {
            return try await biometricFlow.resendMFA(sessionId: session.id)
        }
        return try await loginFlow.resendMFA(sessionId: session.id)
    }

    @discardableResult
    public func verifyLoginMFA(code: String) async throws -> LoginMFAResult {
        guard let session = try await sessionStore.load() else {
            throw AuthError(code: .noActiveSession, message: "No session for MFA")
        }
        let result: LoginMFAResult
        if await biometricFlow.isMFAActive() {
            result = try await biometricFlow.verifyMFA(sessionId: session.id, code: code)
        } else {
            result = try await loginFlow.verifyMFA(sessionId: session.id, code: code)
        }
        try await sessionStore.save(result.session)
        emit(.loggedIn(result.session))
        return result
    }

    public func exchangeTokens() async throws -> TokenSet {
        guard let session = try await sessionStore.load() else {
            throw AuthError(code: .noActiveSession, message: "No session to exchange")
        }
        let tokens = try await tokenService.exchange(sessionId: session.id)
        emit(.tokensUpdated(tokens))
        return tokens
    }
}
