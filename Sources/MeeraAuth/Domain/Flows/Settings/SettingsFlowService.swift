//
//  SettingsFlowService.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

protocol SettingsFlowServing: Sendable {
    func start(sessionId: String?, accessToken: String?) async throws
    @discardableResult
    func verifyCivilId(sessionId: String, civilId: String, expiry: String) async throws -> CivilIdVerificationResult
    @discardableResult
    func sendMobileCode(
        sessionId: String,
        mobile: String,
        username: String?,
        civilIdUpdate: Bool,
        useCivilIDMobile: Bool
    ) async throws -> [AuthFlowNotice]
    @discardableResult
    func verifyMobileCode(sessionId: String, code: String) async throws -> [AuthFlowNotice]
    @discardableResult
    func sendEmailCode(sessionId: String, email: String) async throws -> [AuthFlowNotice]
    @discardableResult
    func verifyEmailCode(sessionId: String, code: String) async throws -> [AuthFlowNotice]
    @discardableResult
    func confirmBindCivilId(sessionId: String) async throws -> [AuthFlowNotice]
    @discardableResult
    func updatePassword(sessionId: String, password: String, confirmPassword: String) async throws -> [AuthFlowNotice]
}

actor SettingsFlowService: SettingsFlowServing {
    private let api: SSOAPIClient
    private let config: AuthConfiguration
    private var flowId: String?
    private var flowTokenId: String?
    private var lastUsername: String?

    init(api: SSOAPIClient, config: AuthConfiguration) {
        self.api = api
        self.config = config
    }

    func start(sessionId: String?, accessToken: String?) async throws {
        guard sessionId != nil || accessToken != nil else {
            throw AuthError(code: .noActiveSession, message: "Settings require X-SESSION-ID or Bearer token")
        }
        let response = try await api.execute(
            SettingsRequest.start(sessionId: sessionId, accessToken: accessToken)
        )
        let flow = try FlowJSONParser.parse(response.data)
        flowId = flow.id
        lastUsername = nil
    }

    @discardableResult
    func verifyCivilId(sessionId: String, civilId: String, expiry: String) async throws -> CivilIdVerificationResult {
        guard let flowId else { throw AuthError(code: .invalidState, message: "Call start() first") }
        let response = try await api.execute(
            SettingsRequest.verifyCivilId(
                flowId: flowId,
                sessionId: sessionId,
                civilId: civilId,
                expiry: expiry,
                method: config.civilIdMethod.rawValue
            )
        )
        let flow = try parse(response)
        self.flowId = flow.id
        let username = flow.usernameHint
        self.lastUsername = username
        return CivilIdVerificationResult(
            username: username,
            notices: AuthFlowNotice.notices(from: flow.messages)
        )
    }

    @discardableResult
    func sendMobileCode(
        sessionId: String,
        mobile: String,
        username: String?,
        civilIdUpdate: Bool,
        useCivilIDMobile: Bool
    ) async throws -> [AuthFlowNotice] {
        guard let flowId else { throw AuthError(code: .invalidState, message: "Call start() first") }
        let trimmed = username?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedUsername: String?
        if let trimmed, !trimmed.isEmpty {
            resolvedUsername = trimmed
        } else {
            resolvedUsername = lastUsername
        }
        lastUsername = resolvedUsername
        let response = try await api.execute(
            SettingsRequest.sendMobileCode(
                flowId: flowId,
                sessionId: sessionId,
                mobile: mobile,
                resource: config.resolvedResources.activeMobile,
                username: resolvedUsername,
                civilIdUpdate: civilIdUpdate,
                useCivilIDMobile: useCivilIDMobile,
                method: config.civilIdMethod.rawValue
            )
        )
        let flow = try parse(response)
        self.flowId = flow.id
        self.flowTokenId = flow.flowTokenId
        return AuthFlowNotice.notices(from: flow.messages)
    }

    @discardableResult
    func verifyMobileCode(sessionId: String, code: String) async throws -> [AuthFlowNotice] {
        guard let flowId, let flowTokenId else {
            throw AuthError(code: .invalidState, message: "Send mobile code first")
        }
        let response = try await api.execute(
            SettingsRequest.verifyMobileCode(
                flowId: flowId,
                sessionId: sessionId,
                flowTokenId: flowTokenId,
                code: code,
                method: config.civilIdMethod.rawValue
            )
        )
        let flow = try parse(response)
        self.flowId = flow.id
        self.flowTokenId = flow.flowTokenId
        return AuthFlowNotice.notices(from: flow.messages)
    }

    @discardableResult
    func sendEmailCode(sessionId: String, email: String) async throws -> [AuthFlowNotice] {
        guard let flowId else { throw AuthError(code: .invalidState, message: "Call start() first") }
        let response = try await api.execute(
            SettingsRequest.sendEmailCode(
                flowId: flowId,
                sessionId: sessionId,
                email: email,
                resource: config.resolvedResources.activeEmail,
                method: config.civilIdMethod.rawValue
            )
        )
        let flow = try parse(response)
        self.flowId = flow.id
        self.flowTokenId = flow.flowTokenId
        return AuthFlowNotice.notices(from: flow.messages)
    }

    @discardableResult
    func verifyEmailCode(sessionId: String, code: String) async throws -> [AuthFlowNotice] {
        guard let flowId, let flowTokenId else {
            throw AuthError(code: .invalidState, message: "Send email code first")
        }
        let response = try await api.execute(
            SettingsRequest.verifyEmailCode(
                flowId: flowId,
                sessionId: sessionId,
                flowTokenId: flowTokenId,
                code: code,
                method: config.civilIdMethod.rawValue
            )
        )
        let flow = try parse(response)
        self.flowId = flow.id
        return AuthFlowNotice.notices(from: flow.messages)
    }

    @discardableResult
    func confirmBindCivilId(sessionId: String) async throws -> [AuthFlowNotice] {
        guard let flowId else { throw AuthError(code: .invalidState, message: "Call start() first") }
        let response = try await api.execute(
            SettingsRequest.confirmBindCivilId(
                flowId: flowId,
                sessionId: sessionId,
                method: config.civilIdMethod.rawValue
            )
        )
        let flow = try parse(response)
        return AuthFlowNotice.notices(from: flow.messages)
    }

    @discardableResult
    func updatePassword(sessionId: String, password: String, confirmPassword: String) async throws -> [AuthFlowNotice] {
        guard let flowId else { throw AuthError(code: .invalidState, message: "Call start() first") }
        let response = try await api.execute(
            SettingsRequest.updatePassword(
                flowId: flowId,
                sessionId: sessionId,
                password: password,
                confirmPassword: confirmPassword
            )
        )
        let flow = try parse(response)
        self.flowId = flow.id
        return AuthFlowNotice.notices(from: flow.messages)
    }

    private func parse(_ response: AuthHTTPResponse) throws -> ParsedFlow {
        let flow = try FlowJSONParser.parse(response.data)
        if let err = ErrorMapper.fromFlowMessages(flow.messages, httpStatus: response.statusCode) {
            throw err
        }
        return flow
    }
}
