//
//  RegistrationFlowService.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 06/08/2026.
//

import Foundation

enum RegistrationOutcome: Sendable, Equatable {
    case requiresVerification(flowId: String, flowTokenId: String?)
    case completed(Session?)
}

protocol RegistrationFlowServing: Sendable {
    func start() async throws
    func submitPassword(_ profile: RegistrationProfile) async throws -> RegistrationOutcome
    @discardableResult
    func verifyCivilId(_ civilId: String, expiry: String) async throws -> CivilIdVerificationResult
    @discardableResult
    func sendMobileOTP(mobile: String, username: String?, useCivilIDMobile: Bool) async throws -> [AuthFlowNotice]
    @discardableResult
    func resendMobileOTP() async throws -> [AuthFlowNotice]
    @discardableResult
    func verifyMobileOTP(_ code: String) async throws -> [AuthFlowNotice]
    @discardableResult
    func sendEmailOTP(_ email: String) async throws -> [AuthFlowNotice]
    @discardableResult
    func resendEmailOTP() async throws -> [AuthFlowNotice]
    @discardableResult
    func verifyEmailOTP(_ code: String) async throws -> [AuthFlowNotice]
    func submitCivilIdPassword(password: String, confirmPassword: String) async throws -> RegistrationOutcome
}

actor RegistrationFlowService: RegistrationFlowServing {
    private let api: SSOAPIClient
    private let config: AuthConfiguration

    private var flowId: String?
    private var flowTokenId: String?
    private var lastMobile: String?
    private var lastUsername: String?
    private var lastUseCivilIDMobile: Bool = true
    private var lastEmail: String?

    init(api: SSOAPIClient, config: AuthConfiguration) {
        self.api = api
        self.config = config
    }

    func start() async throws {
        guard !config.signupOptions.isEmpty else {
            throw AuthError.signupDisabled()
        }
        let response = try await api.execute(RegistrationRequest.start)
        let flow = try parseFlowOrThrow(response)
        flowId = flow.id
        flowTokenId = flow.flowTokenId
        lastMobile = nil
        lastUsername = nil
        lastEmail = nil
    }

    func submitPassword(_ profile: RegistrationProfile) async throws -> RegistrationOutcome {
        try ensureSignup(.basic)
        guard let flowId else { throw AuthError(code: .invalidState, message: "Call startRegistration() first") }
        let resource: String
        if !profile.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            resource = config.resolvedResources.activeEmail
        } else {
            resource = config.resolvedResources.activeMobile
        }
        let response = try await api.execute(
            RegistrationRequest.submitPassword(
                flowId: flowId,
                profile: profile,
                resource: resource
            )
        )
        return try interpretCompletion(response)
    }

    @discardableResult
    func verifyCivilId(_ civilId: String, expiry: String) async throws -> CivilIdVerificationResult {
        try ensureSignup(.civilId)
        guard let flowId else { throw AuthError(code: .invalidState, message: "Call startRegistration() first") }
        let response = try await api.execute(
            RegistrationRequest.verifyCivilId(
                flowId: flowId,
                civilId: civilId,
                expiry: expiry,
                method: config.civilIdMethod.rawValue
            )
        )
        let flow = try parseFlowOrThrow(response)
        self.flowId = flow.id
        self.flowTokenId = flow.flowTokenId ?? flowTokenId
        let username = flow.usernameHint
        self.lastUsername = username
        return CivilIdVerificationResult(
            username: username,
            notices: AuthFlowNotice.notices(from: flow.messages)
        )
    }

    func sendMobileOTP(mobile: String, username: String?, useCivilIDMobile: Bool) async throws -> [AuthFlowNotice] {
        try ensureSignup(.civilId)
        guard let flowId else { throw AuthError(code: .invalidState, message: "Call startRegistration() first") }
        let trimmed = username?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedUsername: String?
        if let trimmed, !trimmed.isEmpty {
            resolvedUsername = trimmed
        } else {
            resolvedUsername = lastUsername
        }
        lastMobile = mobile
        lastUsername = resolvedUsername
        lastUseCivilIDMobile = useCivilIDMobile
        let response = try await api.execute(
            RegistrationRequest.sendMobileOTP(
                flowId: flowId,
                mobile: mobile,
                username: resolvedUsername,
                resource: config.resolvedResources.activeMobile,
                useCivilIDMobile: useCivilIDMobile,
                flowTokenId: nil,
                method: config.civilIdMethod.rawValue
            )
        )
        let flow = try parseFlowOrThrow(response)
        self.flowId = flow.id
        self.flowTokenId = flow.flowTokenId ?? flowTokenId
        return AuthFlowNotice.notices(from: flow.messages)
    }

    func resendMobileOTP() async throws -> [AuthFlowNotice] {
        try ensureSignup(.civilId)
        guard let flowId, let mobile = lastMobile else {
            throw AuthError(code: .invalidState, message: "Send mobile OTP first")
        }
        let response = try await api.execute(
            RegistrationRequest.sendMobileOTP(
                flowId: flowId,
                mobile: mobile,
                username: lastUsername,
                resource: config.resolvedResources.activeMobile,
                useCivilIDMobile: lastUseCivilIDMobile,
                flowTokenId: flowTokenId,
                method: config.civilIdMethod.rawValue
            )
        )
        let flow = try parseFlowOrThrow(response)
        self.flowId = flow.id
        self.flowTokenId = flow.flowTokenId ?? flowTokenId
        return AuthFlowNotice.notices(from: flow.messages)
    }

    func verifyMobileOTP(_ code: String) async throws -> [AuthFlowNotice] {
        try ensureSignup(.civilId)
        guard let flowId, let flowTokenId else {
            throw AuthError(code: .invalidState, message: "Send mobile OTP first")
        }
        let response = try await api.execute(
            RegistrationRequest.verifyOTP(
                flowId: flowId,
                code: code,
                flowTokenId: flowTokenId,
                method: config.civilIdMethod.rawValue,
                resource: config.resolvedResources.activeMobile
            )
        )
        let flow = try parseFlowOrThrow(response)
        self.flowId = flow.id
        self.flowTokenId = flow.flowTokenId ?? flowTokenId
        return AuthFlowNotice.notices(from: flow.messages)
    }

    func sendEmailOTP(_ email: String) async throws -> [AuthFlowNotice] {
        try ensureSignup(.civilId)
        guard let flowId else { throw AuthError(code: .invalidState, message: "Call startRegistration() first") }
        lastEmail = email
        // First send matches Tawteen: email + resource + method only (no flowTokenId).
        let response = try await api.execute(
            RegistrationRequest.sendEmailOTP(
                flowId: flowId,
                email: email,
                resource: config.resolvedResources.activeEmail,
                flowTokenId: nil,
                method: config.civilIdMethod.rawValue
            )
        )
        let flow = try parseFlowOrThrow(response)
        self.flowId = flow.id
        self.flowTokenId = flow.flowTokenId ?? flowTokenId
        return AuthFlowNotice.notices(from: flow.messages)
    }

    func resendEmailOTP() async throws -> [AuthFlowNotice] {
        try ensureSignup(.civilId)
        guard let flowId, let email = lastEmail else {
            throw AuthError(code: .invalidState, message: "Send email OTP first")
        }
        let response = try await api.execute(
            RegistrationRequest.sendEmailOTP(
                flowId: flowId,
                email: email,
                resource: config.resolvedResources.activeEmail,
                flowTokenId: flowTokenId,
                method: config.civilIdMethod.rawValue
            )
        )
        let flow = try parseFlowOrThrow(response)
        self.flowId = flow.id
        self.flowTokenId = flow.flowTokenId ?? flowTokenId
        return AuthFlowNotice.notices(from: flow.messages)
    }

    func verifyEmailOTP(_ code: String) async throws -> [AuthFlowNotice] {
        try ensureSignup(.civilId)
        guard let flowId, let flowTokenId else {
            throw AuthError(code: .invalidState, message: "Send email OTP first")
        }
        let response = try await api.execute(
            RegistrationRequest.verifyOTP(
                flowId: flowId,
                code: code,
                flowTokenId: flowTokenId,
                method: config.civilIdMethod.rawValue,
                resource: config.resolvedResources.activeEmail
            )
        )
        let flow = try parseFlowOrThrow(response)
        self.flowId = flow.id
        self.flowTokenId = flow.flowTokenId ?? flowTokenId
        return AuthFlowNotice.notices(from: flow.messages)
    }

    func submitCivilIdPassword(password: String, confirmPassword: String) async throws -> RegistrationOutcome {
        try ensureSignup(.civilId)
        guard let flowId else { throw AuthError(code: .invalidState, message: "Call startRegistration() first") }
        let response = try await api.execute(
            RegistrationRequest.submitCivilIdPassword(
                flowId: flowId,
                password: password,
                confirmPassword: confirmPassword,
                method: config.civilIdMethod.rawValue
            )
        )
        return try interpretCompletion(response)
    }
}

extension RegistrationFlowService {
    private func ensureSignup(_ option: SignupOption) throws {
        guard config.signupOptions.contains(option) else {
            throw AuthError.signupMethodDisabled(option, enabled: config.signupOptions)
        }
    }

    private func interpretCompletion(_ response: AuthHTTPResponse) throws -> RegistrationOutcome {
        if looksLikeIdentity(response.data) {
            return .completed(nil)
        }
        if looksLikeSession(response.data) {
            let session = try FlowJSONParser.parseSession(response.data)
            return .completed(session)
        }
        if let flow = try? FlowJSONParser.parse(response.data) {
            if let err = ErrorMapper.fromFlowMessages(flow.messages, httpStatus: response.statusCode) {
                throw err
            }
            if flow.pointsToVerification
                || flow.messages.contains(where: {
                    $0.text.localizedCaseInsensitiveContains("verification")
                }) {
                return .requiresVerification(flowId: flow.id, flowTokenId: flow.flowTokenId)
            }
            if flow.messages.contains(where: {
                $0.text.localizedCaseInsensitiveContains("registration has been completed")
                    || $0.code == AuthErrorCode.completedByStrategy.rawValue
            }) {
                return .completed(nil)
            }
            self.flowId = flow.id
            self.flowTokenId = flow.flowTokenId ?? flowTokenId
            throw AuthError(
                code: .unknown,
                message: "Unexpected registration response",
                httpStatus: response.statusCode
            )
        }
        throw AuthError(code: .decoding, message: "Unexpected registration payload", httpStatus: response.statusCode)
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
        return obj["id"] != nil
            && (obj["authenticatorAssuranceLevel"] != nil || obj.keys.contains("identity"))
            && obj["ui"] == nil
    }

    private func looksLikeIdentity(_ data: Data) -> Bool {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return false }
        return obj["userId"] != nil && obj["ui"] == nil && obj["authenticatorAssuranceLevel"] == nil
    }
}
