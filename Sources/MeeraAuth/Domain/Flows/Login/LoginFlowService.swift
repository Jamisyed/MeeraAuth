//
//  LoginFlowService.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

protocol LoginFlowServing: Sendable {
    func start() async throws
    func submit(option: LoginOption, identifier: String, password: String) async throws -> LoginStep
    @discardableResult
    func sendMFA(sessionId: String) async throws -> [AuthFlowNotice]
    @discardableResult
    func resendMFA(sessionId: String) async throws -> [AuthFlowNotice]
    @discardableResult
    func verifyMFA(sessionId: String, code: String) async throws -> LoginMFAResult
}

actor LoginFlowService: LoginFlowServing {
    private let api: SSOAPIClient
    private let config: AuthConfiguration

    private var flowId: String?
    private var flowTokenId: String?
    private var mfaChannel: MFAChannel?
    private var identifierCache: (option: LoginOption, value: String)?

    init(api: SSOAPIClient, config: AuthConfiguration) {
        self.api = api
        self.config = config
    }

    func start() async throws {
        let response = try await api.execute(LoginRequest.start)
        let flow = try parseFlowOrThrow(response)
        flowId = flow.id
        flowTokenId = flow.flowTokenId
    }

    func submit(
        option: LoginOption,
        identifier: String,
        password: String
    ) async throws -> LoginStep {
        try ensureOption(option)
        guard let flowId else { throw AuthError(code: .invalidState, message: "Call start() first") }
        identifierCache = (option, identifier)

        let method = option == .civilId ? config.civilIdMethod.rawValue : "password"
        let response = try await api.execute(
            LoginRequest.submit(
                flowId: flowId,
                option: option,
                identifier: identifier,
                password: password,
                method: method
            )
        )

        if let flowError = try? FlowJSONParser.parse(response.data),
           let err = ErrorMapper.fromFlowMessages(flowError.messages, httpStatus: response.statusCode) {
            throw err
        }

        if looksLikeSession(response.data) {
            let session = try FlowJSONParser.parseSession(response.data)
            if session.requiresMFA {
                return try await beginMFA(sessionId: session.id)
            }
            var notices: [AuthFlowNotice] = []
            if let flow = try? FlowJSONParser.parse(response.data) {
                notices = AuthFlowNotice.notices(from: flow.messages)
            }
            return .authenticated(session: session, notices: notices)
        }

        let flow = try parseFlowOrThrow(response)
        self.flowId = flow.id
        throw AuthError(code: .unknown, message: "Unexpected login response", httpStatus: response.statusCode)
    }

    @discardableResult
    func sendMFA(sessionId: String) async throws -> [AuthFlowNotice] {
        guard let flowId, let channel = mfaChannel else {
            throw AuthError(code: .invalidState, message: "MFA not started")
        }

        let resources = config.resolvedResources
        var email: String?
        var mobile: String?

        switch channel {
        case .email:
            if let value = identifierCache?.value, identifierCache?.option == .email {
                email = value
            } else {
                email = try? await currentEmailHint(sessionId: sessionId)
            }
        case .sms:
            if let value = identifierCache?.value, identifierCache?.option == .phone {
                mobile = value
            } else {
                mobile = try? await currentMobileHint(sessionId: sessionId)
            }
        }

        let response = try await api.execute(
            LoginRequest.sendMFA(
                flowId: flowId,
                sessionId: sessionId,
                channel: channel,
                resource: channel == .email ? resources.emailOTP : resources.mobileOTP,
                email: email,
                mobile: mobile,
                flowTokenId: flowTokenId
            )
        )
        let flow = try parseFlowOrThrow(response)
        self.flowId = flow.id
        self.flowTokenId = flow.flowTokenId ?? flowTokenId
        return AuthFlowNotice.notices(from: flow.messages)
    }

    @discardableResult
    func resendMFA(sessionId: String) async throws -> [AuthFlowNotice] {
        try await sendMFA(sessionId: sessionId)
    }

    @discardableResult
    func verifyMFA(sessionId: String, code: String) async throws -> LoginMFAResult {
        guard let flowId, let channel = mfaChannel, let flowTokenId else {
            throw AuthError(code: .invalidState, message: "MFA not ready — send OTP first")
        }
        let response = try await api.execute(
            LoginRequest.verifyMFA(
                flowId: flowId,
                sessionId: sessionId,
                channel: channel,
                code: code,
                flowTokenId: flowTokenId,
                emailResource: channel == .email ? config.resolvedResources.emailOTP : nil
            )
        )
        var notices: [AuthFlowNotice] = []
        if let flow = try? FlowJSONParser.parse(response.data) {
            if let err = ErrorMapper.fromFlowMessages(flow.messages, httpStatus: response.statusCode) {
                throw err
            }
            notices = AuthFlowNotice.notices(from: flow.messages)
        }
        let session = try FlowJSONParser.parseSession(response.data)
        guard session.identity != nil else {
            throw AuthError(code: .aalNotSatisfied, message: "MFA did not complete")
        }
        return LoginMFAResult(session: session, notices: notices)
    }

    // MARK: - Private

    private func beginMFA(sessionId: String) async throws -> LoginStep {
        let response = try await api.execute(LoginRequest.startMFA(sessionId: sessionId))
        let flow = try parseFlowOrThrow(response)
        flowId = flow.id
        flowTokenId = flow.flowTokenId
        let channel: MFAChannel
        switch flow.active {
        case "mfases":
            channel = .email
        case "mfasms":
            channel = .sms
        default:
            throw AuthError(
                code: .invalidState,
                message: "MFA channel unknown — expected flow.active mfases or mfasms, got \(flow.active ?? "nil")"
            )
        }
        mfaChannel = channel
        var notices: [AuthFlowNotice] = []
        if config.mfaPolicy.autoSendOTP {
            notices = try await sendMFA(sessionId: sessionId)
        }
        return .requiresMFA(channel: channel, sessionId: sessionId, notices: notices)
    }

    private func currentEmailHint(sessionId: String) async throws -> String? {
        guard let flowId else { return nil }
        let response = try await api.execute(
            LoginRequest.flowHints(flowId: flowId, sessionId: sessionId)
        )
        return try? FlowJSONParser.parse(response.data).emailHint
    }

    private func currentMobileHint(sessionId: String) async throws -> String? {
        guard let flowId else { return nil }
        let response = try await api.execute(
            LoginRequest.flowHints(flowId: flowId, sessionId: sessionId)
        )
        return try? FlowJSONParser.parse(response.data).mobileHint
    }

    private func ensureOption(_ option: LoginOption) throws {
        guard config.loginOptions.contains(option) else {
            throw AuthError.methodDisabled(option, enabled: config.loginOptions)
        }
    }

    private func parseFlowOrThrow(_ response: AuthHTTPResponse) throws -> ParsedFlow {
        if response.statusCode >= 400, response.data.isEmpty {
            throw AuthError.network("HTTP \(response.statusCode)", status: response.statusCode)
        }
        let flow = try FlowJSONParser.parse(response.data)
        if let err = ErrorMapper.fromFlowMessages(flow.messages, httpStatus: response.statusCode) {
            throw err
        }
        return flow
    }

    private func looksLikeSession(_ data: Data) -> Bool {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return false }
        if obj["session"] is [String: Any] { return true }
        return obj["id"] != nil && (obj["authenticatorAssuranceLevel"] != nil || obj.keys.contains("identity"))
    }
}
