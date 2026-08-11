//
//  AuthClient+Registration.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 06/08/2026.
//

import Foundation

extension AuthClient {
    // MARK: - Registration

    public func startRegistration() async throws {
        try await registrationFlow.start()
    }

    public func register(_ profile: RegistrationProfile) async throws -> RegistrationStep {
        let outcome = try await registrationFlow.submitPassword(profile)
        return try await applyRegistrationOutcome(outcome)
    }

    @discardableResult
    public func verifyRegistrationCivilId(_ civilId: String, expiry: String) async throws -> CivilIdVerificationResult {
        try await registrationFlow.verifyCivilId(civilId, expiry: expiry)
    }

    @discardableResult
    public func sendRegistrationMobileOTP(
        mobile: String,
        username: String? = nil,
        useCivilIDMobile: Bool = true
    ) async throws -> [AuthFlowNotice] {
        try await registrationFlow.sendMobileOTP(
            mobile: mobile,
            username: username,
            useCivilIDMobile: useCivilIDMobile
        )
    }

    @discardableResult
    public func resendRegistrationMobileOTP() async throws -> [AuthFlowNotice] {
        try await registrationFlow.resendMobileOTP()
    }

    @discardableResult
    public func verifyRegistrationMobileOTP(_ code: String) async throws -> [AuthFlowNotice] {
        try await registrationFlow.verifyMobileOTP(code)
    }

    @discardableResult
    public func sendRegistrationEmailOTP(_ email: String) async throws -> [AuthFlowNotice] {
        try await registrationFlow.sendEmailOTP(email)
    }

    @discardableResult
    public func resendRegistrationEmailOTP() async throws -> [AuthFlowNotice] {
        try await registrationFlow.resendEmailOTP()
    }

    @discardableResult
    public func verifyRegistrationEmailOTP(_ code: String) async throws -> [AuthFlowNotice] {
        try await registrationFlow.verifyEmailOTP(code)
    }

    public func submitRegistrationPassword(
        password: String,
        confirmPassword: String
    ) async throws -> RegistrationStep {
        let outcome = try await registrationFlow.submitCivilIdPassword(
            password: password,
            confirmPassword: confirmPassword
        )
        return try await applyRegistrationOutcome(outcome)
    }

    func applyRegistrationOutcome(_ outcome: RegistrationOutcome) async throws -> RegistrationStep {
        switch outcome {
        case let .requiresVerification(flowId, flowTokenId):
            await verificationFlow.seed(flowId: flowId, flowTokenId: flowTokenId)
            return .requiresVerification
        case let .completed(session):
            if let session {
                try await sessionStore.save(session)
                emit(.sessionUpdated(session))
                if session.identity != nil {
                    emit(.loggedIn(session))
                }
            }
            return .completed(session)
        }
    }
}
