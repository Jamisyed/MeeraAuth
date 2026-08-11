//
//  AuthClient+Recovery.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 06/08/2026.
//

import Foundation

extension AuthClient {
    // MARK: - Recovery

    public func startRecovery() async throws {
        try await recoveryFlow.start()
    }

    @discardableResult
    public func recoverySendCode(option: LoginOption, identifier: String) async throws -> [AuthFlowNotice] {
        try await recoveryFlow.sendCode(option: option, identifier: identifier)
    }

    @discardableResult
    public func recoveryResendCode() async throws -> [AuthFlowNotice] {
        try await recoveryFlow.resendCode()
    }

    @discardableResult
    public func recoveryVerifyCode(_ code: String) async throws -> RecoveryVerifyResult {
        let result = try await recoveryFlow.verifyCode(code)
        try await sessionStore.save(result.session)
        emit(.sessionUpdated(result.session))
        return result
    }
}
