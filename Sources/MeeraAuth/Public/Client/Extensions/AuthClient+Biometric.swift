//
//  AuthClient+Biometric.swift
//  MeeraAuth
//

import Foundation

extension AuthClient {
    // MARK: - Biometric

    public func startBiometricLogin() async throws {
        try await biometricFlow.startLogin()
    }

    public func loginWithBiometric(
        identifier: String,
        name: String,
        biometricAuthKey: String
    ) async throws -> LoginStep {
        let step = try await biometricFlow.login(
            identifier: identifier,
            name: name,
            biometricAuthKey: biometricAuthKey
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

    public func startBiometricSettings() async throws {
        let sessionId = try await sessionStore.load()?.id
        let token = try await tokenStore.load()?.accessToken
        try await biometricFlow.startSettings(sessionId: sessionId, accessToken: token)
    }

    @discardableResult
    public func settingsBindBiometric(
        identifier: String,
        name: String,
        biometricAuthKey: String
    ) async throws -> [AuthFlowNotice] {
        guard let sessionId = try await sessionStore.load()?.id else {
            throw AuthError(code: .noActiveSession, message: "Settings require a session")
        }
        return try await biometricFlow.bind(
            sessionId: sessionId,
            identifier: identifier,
            name: name,
            biometricAuthKey: biometricAuthKey
        )
    }

    @discardableResult
    public func settingsUnbindBiometric(
        identifier: String,
        name: String,
        biometricAuthKey: String
    ) async throws -> [AuthFlowNotice] {
        guard let sessionId = try await sessionStore.load()?.id else {
            throw AuthError(code: .noActiveSession, message: "Settings require a session")
        }
        return try await biometricFlow.unbind(
            sessionId: sessionId,
            identifier: identifier,
            name: name,
            biometricAuthKey: biometricAuthKey
        )
    }
}
