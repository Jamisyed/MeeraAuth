//
//  BiometricFlowService.swift
//  MeeraAuth
//

import Foundation

protocol BiometricFlowServing: Sendable {
    func startLogin() async throws
    func login(identifier: String, name: String, biometricAuthKey: String) async throws -> LoginStep
    func startSettings(sessionId: String?, accessToken: String?) async throws
    @discardableResult
    func bind(
        sessionId: String,
        identifier: String,
        name: String,
        biometricAuthKey: String
    ) async throws -> [AuthFlowNotice]
    @discardableResult
    func unbind(
        sessionId: String,
        identifier: String,
        name: String,
        biometricAuthKey: String
    ) async throws -> [AuthFlowNotice]
    func isMFAActive() async -> Bool
    @discardableResult
    func sendMFA(sessionId: String) async throws -> [AuthFlowNotice]
    @discardableResult
    func resendMFA(sessionId: String) async throws -> [AuthFlowNotice]
    @discardableResult
    func verifyMFA(sessionId: String, code: String) async throws -> LoginMFAResult
}

actor BiometricFlowService: BiometricFlowServing {
    private let api: SSOAPIClient
    private let config: AuthConfiguration

    private var loginFlowId: String?
    private var settingsFlowId: String?
    private var flowTokenId: String?
    private var mfaChannel: MFAChannel?
    private var loginIdentifier: String?

    init(api: SSOAPIClient, config: AuthConfiguration) {
        self.api = api
        self.config = config
    }

    func isMFAActive() async -> Bool {
        mfaChannel != nil
    }

    func startLogin() async throws {
        let response = try await api.execute(LoginRequest.start)
        let flow = try parseFlowOrThrow(response)
        loginFlowId = flow.id
        flowTokenId = flow.flowTokenId
        mfaChannel = nil
    }

    func login(
        identifier: String,
        name: String,
        biometricAuthKey: String
    ) async throws -> LoginStep {
        guard let flowId = loginFlowId else {
            throw AuthError(code: .invalidState, message: "Call startBiometricLogin() first")
        }
        loginIdentifier = identifier

        let response = try await api.execute(
            LoginRequest.submitBiometric(
                flowId: flowId,
                identifier: identifier,
                name: name,
                biometricAuthKey: biometricAuthKey
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
        loginFlowId = flow.id
        throw AuthError(
            code: .unknown,
            message: "Unexpected biometric login response",
            httpStatus: response.statusCode
        )
    }

    func startSettings(sessionId: String?, accessToken: String?) async throws {
        guard sessionId != nil || accessToken != nil else {
            throw AuthError(code: .noActiveSession, message: "Settings require X-SESSION-ID or Bearer token")
        }
        let response = try await api.execute(
            SettingsRequest.start(sessionId: sessionId, accessToken: accessToken)
        )
        let flow = try FlowJSONParser.parse(response.data)
        settingsFlowId = flow.id
    }

    @discardableResult
    func bind(
        sessionId: String,
        identifier: String,
        name: String,
        biometricAuthKey: String
    ) async throws -> [AuthFlowNotice] {
        guard let flowId = settingsFlowId else {
            throw AuthError(code: .invalidState, message: "Call startBiometricSettings() first")
        }
        let response = try await api.execute(
            SettingsRequest.bindBiometric(
                flowId: flowId,
                sessionId: sessionId,
                identifier: identifier,
                name: name,
                biometricAuthKey: biometricAuthKey
            )
        )
        let flow = try parseSettings(response)
        settingsFlowId = flow.id
        return AuthFlowNotice.notices(from: flow.messages)
    }

    @discardableResult
    func unbind(
        sessionId: String,
        identifier: String,
        name: String,
        biometricAuthKey: String
    ) async throws -> [AuthFlowNotice] {
        guard let flowId = settingsFlowId else {
            throw AuthError(code: .invalidState, message: "Call startBiometricSettings() first")
        }
        let response = try await api.execute(
            SettingsRequest.unbindBiometric(
                flowId: flowId,
                sessionId: sessionId,
                identifier: identifier,
                name: name,
                biometricAuthKey: biometricAuthKey
            )
        )
        let flow = try parseSettings(response)
        settingsFlowId = flow.id
        return AuthFlowNotice.notices(from: flow.messages)
    }

    @discardableResult
    func sendMFA(sessionId: String) async throws -> [AuthFlowNotice] {
        guard let flowId = loginFlowId, let channel = mfaChannel else {
            throw AuthError(code: .invalidState, message: "Biometric MFA not started")
        }

        let resources = config.resolvedResources
        var email: String?
        var mobile: String?
        switch channel {
        case .email:
            if let loginIdentifier {
                email = loginIdentifier
            } else {
                email = try? await currentEmailHint(sessionId: sessionId)
            }
        case .sms:
            if let loginIdentifier {
                mobile = loginIdentifier
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
        loginFlowId = flow.id
        flowTokenId = flow.flowTokenId ?? flowTokenId
        return AuthFlowNotice.notices(from: flow.messages)
    }

    @discardableResult
    func resendMFA(sessionId: String) async throws -> [AuthFlowNotice] {
        try await sendMFA(sessionId: sessionId)
    }

    @discardableResult
    func verifyMFA(sessionId: String, code: String) async throws -> LoginMFAResult {
        guard let flowId = loginFlowId, let channel = mfaChannel, let flowTokenId else {
            throw AuthError(code: .invalidState, message: "Biometric MFA not ready — send OTP first")
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
        mfaChannel = nil
        return LoginMFAResult(session: session, notices: notices)
    }

    // MARK: - Private

    private func beginMFA(sessionId: String) async throws -> LoginStep {
        let response = try await api.execute(LoginRequest.startMFA(sessionId: sessionId))
        let flow = try parseFlowOrThrow(response)
        loginFlowId = flow.id
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
        guard let flowId = loginFlowId else { return nil }
        let response = try await api.execute(
            LoginRequest.flowHints(flowId: flowId, sessionId: sessionId)
        )
        return try? FlowJSONParser.parse(response.data).emailHint
    }

    private func currentMobileHint(sessionId: String) async throws -> String? {
        guard let flowId = loginFlowId else { return nil }
        let response = try await api.execute(
            LoginRequest.flowHints(flowId: flowId, sessionId: sessionId)
        )
        return try? FlowJSONParser.parse(response.data).mobileHint
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

    private func parseSettings(_ response: AuthHTTPResponse) throws -> ParsedFlow {
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
