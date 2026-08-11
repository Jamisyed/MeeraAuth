//
//  AuthClientServing.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

protocol AuthClientServing: Actor {
    // MARK: - Configuration

    nonisolated var configuration: AuthConfiguration { get }

    // MARK: - Events

    func events() -> AsyncStream<AuthEvent>

    // MARK: - Session / tokens

    func currentSession() async throws -> Session?
    func currentTokens() async throws -> TokenSet?
    func accessToken() async throws -> String?
    func validAccessToken(skew: TimeInterval) async throws -> String
    @discardableResult
    func refreshTokens() async throws -> TokenSet

    // MARK: - Login

    func startLogin() async throws
    func login(option: LoginOption, identifier: String, password: String) async throws -> LoginStep
    @discardableResult
    func sendLoginMFA() async throws -> [AuthFlowNotice]
    @discardableResult
    func resendLoginMFA() async throws -> [AuthFlowNotice]
    @discardableResult
    func verifyLoginMFA(code: String) async throws -> LoginMFAResult
    func exchangeTokens() async throws -> TokenSet

    // MARK: - Registration

    func startRegistration() async throws
    func register(_ profile: RegistrationProfile) async throws -> RegistrationStep
    func verifyRegistrationCivilId(_ civilId: String, expiry: String) async throws -> CivilIdVerificationResult
    @discardableResult
    func sendRegistrationMobileOTP(mobile: String, username: String?, useCivilIDMobile: Bool) async throws -> [AuthFlowNotice]
    @discardableResult
    func resendRegistrationMobileOTP() async throws -> [AuthFlowNotice]
    @discardableResult
    func verifyRegistrationMobileOTP(_ code: String) async throws -> [AuthFlowNotice]
    @discardableResult
    func sendRegistrationEmailOTP(_ email: String) async throws -> [AuthFlowNotice]
    @discardableResult
    func resendRegistrationEmailOTP() async throws -> [AuthFlowNotice]
    @discardableResult
    func verifyRegistrationEmailOTP(_ code: String) async throws -> [AuthFlowNotice]
    func submitRegistrationPassword(password: String, confirmPassword: String) async throws -> RegistrationStep

    // MARK: - Recovery

    func startRecovery() async throws
    @discardableResult
    func recoverySendCode(option: LoginOption, identifier: String) async throws -> [AuthFlowNotice]
    @discardableResult
    func recoveryResendCode() async throws -> [AuthFlowNotice]
    @discardableResult
    func recoveryVerifyCode(_ code: String) async throws -> RecoveryVerifyResult

    // MARK: - Verification

    func startVerification() async throws
    @discardableResult
    func verificationSendOTP(channel: MFAChannel, identifier: String) async throws -> [AuthFlowNotice]
    @discardableResult
    func verificationResendOTP() async throws -> [AuthFlowNotice]
    @discardableResult
    func verificationVerifyOTP(_ code: String) async throws -> [AuthFlowNotice]

    // MARK: - Settings (Civil ID)

    func startSettings() async throws
    @discardableResult
    func settingsVerifyCivilId(_ civilId: String, expiry: String) async throws -> CivilIdVerificationResult
    @discardableResult
    func settingsSendMobileCode(
        mobile: String,
        username: String?,
        civilIdUpdate: Bool,
        useCivilIDMobile: Bool
    ) async throws -> [AuthFlowNotice]
    @discardableResult
    func settingsVerifyMobileCode(_ code: String) async throws -> [AuthFlowNotice]
    @discardableResult
    func settingsSendEmailCode(_ email: String) async throws -> [AuthFlowNotice]
    @discardableResult
    func settingsVerifyEmailCode(_ code: String) async throws -> [AuthFlowNotice]
    @discardableResult
    func settingsConfirmBindCivilId() async throws -> [AuthFlowNotice]
    @discardableResult
    func settingsUpdatePassword(password: String, confirmPassword: String) async throws -> [AuthFlowNotice]

    // MARK: - Logout

    func logout() async throws
}
