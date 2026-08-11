//
//  AuthClient+Verification.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 06/08/2026.
//

import Foundation

extension AuthClient {
    // MARK: - Verification

    public func startVerification() async throws {
        try await verificationFlow.start()
    }

    @discardableResult
    public func verificationSendOTP(channel: MFAChannel, identifier: String) async throws -> [AuthFlowNotice] {
        try await verificationFlow.sendOTP(via: channel, identifier: identifier)
    }

    @discardableResult
    public func verificationResendOTP() async throws -> [AuthFlowNotice] {
        try await verificationFlow.resendOTP()
    }

    @discardableResult
    public func verificationVerifyOTP(_ code: String) async throws -> [AuthFlowNotice] {
        try await verificationFlow.verifyOTP(code)
    }
}
