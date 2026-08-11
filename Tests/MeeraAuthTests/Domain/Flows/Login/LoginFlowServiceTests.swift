//
//  LoginFlowServiceTests.swift
//  MeeraAuthTests
//
//  Created by Syed M Abdul Rehman on 07/08/2026.
//

import XCTest
@testable import MeeraAuth

final class LoginFlowServiceTests: XCTestCase {
    private func makeConfig(autoSendOTP: Bool) -> AuthConfiguration {
        AuthConfiguration(
            ssoEndpoint: URL(string: "https://sso.test10.meeraspace.com")!,
            ssoXEndpoint: URL(string: "https://sso.test10.meeraspace.com/x")!,
            clientId: .mobileApp,
            scopes: [.openid, .offlineAccess],
            locale: .english,
            loginOptions: [.email],
            resources: TestAuthResources.sample,
            mfaPolicy: MFAPolicy(autoSendOTP: autoSendOTP)
        )
    }

    func testLoginRequiresMFAAndAutoSendsOTP() async throws {
        let http = FakeAuthHTTPClient(responses: [
            .ok(FakeSSOJSON.flow(id: "login-flow-1")),
            .ok(FakeSSOJSON.session(id: "sess-1", withIdentity: false)),
            .ok(FakeSSOJSON.flow(id: "mfa-flow-1", flowTokenId: "ft-1", active: "mfases")),
            .ok(FakeSSOJSON.flow(
                id: "mfa-flow-2",
                flowTokenId: "ft-2",
                active: "mfases",
                messages: [[
                    "code": 6062,
                    "type": "info",
                    "text": "The code has been send"
                ]]
            ))
        ])
        let config = makeConfig(autoSendOTP: true)
        let api = SSOAPIClient(http: http, config: config)
        let login = LoginFlowService(api: api, config: config)

        try await login.start()
        let step = try await login.submit(option: .email, identifier: "a@b.com", password: "pw")

        guard case .requiresMFA(let channel, let sessionId, let notices) = step else {
            return XCTFail("expected requiresMFA, got \(step)")
        }
        XCTAssertEqual(channel, .email)
        XCTAssertEqual(sessionId, "sess-1")
        XCTAssertEqual(notices.count, 1)
        XCTAssertEqual(notices[0].code, .codeHasSend)

        let recorded = await http.recorded
        XCTAssertEqual(recorded.count, 4)
        XCTAssertTrue(recorded[0].path.hasSuffix("/login/api"))
        XCTAssertTrue(recorded[1].path.hasSuffix("/login"))
        XCTAssertEqual(recorded[2].query["aal"], "aal2")
        XCTAssertTrue(recorded[3].path.hasSuffix("/login"))
        XCTAssertEqual(recorded[3].headers["X-SESSION-ID"], "sess-1")
    }

    func testSendAndResendMFAReturnNotices() async throws {
        let http = FakeAuthHTTPClient(responses: [
            .ok(FakeSSOJSON.flow(id: "login-flow-1")),
            .ok(FakeSSOJSON.session(id: "sess-1", withIdentity: false)),
            .ok(FakeSSOJSON.flow(id: "mfa-flow-1", flowTokenId: "ft-1", active: "mfases")),
            .ok(FakeSSOJSON.flow(
                id: "mfa-flow-2",
                flowTokenId: "ft-2",
                active: "mfases",
                messages: [[
                    "code": 6062,
                    "type": "info",
                    "text": "The code has been send"
                ]]
            )),
            .ok(FakeSSOJSON.flow(
                id: "mfa-flow-3",
                flowTokenId: "ft-3",
                active: "mfases",
                messages: [[
                    "code": 6063,
                    "type": "info",
                    "text": "The code has been resend"
                ]]
            ))
        ])
        let config = makeConfig(autoSendOTP: false)
        let api = SSOAPIClient(http: http, config: config)
        let login = LoginFlowService(api: api, config: config)

        try await login.start()
        let step = try await login.submit(option: .email, identifier: "a@b.com", password: "pw")
        guard case .requiresMFA(_, let sessionId, let autoNotices) = step else {
            return XCTFail("expected requiresMFA, got \(step)")
        }
        XCTAssertTrue(autoNotices.isEmpty)

        let sent = try await login.sendMFA(sessionId: sessionId)
        XCTAssertEqual(sent.count, 1)
        XCTAssertEqual(sent[0].code, .codeHasSend)

        let resent = try await login.resendMFA(sessionId: sessionId)
        XCTAssertEqual(resent.count, 1)
        XCTAssertEqual(resent[0].code, .codeHasResend)
    }

    func testLoginAuthenticatedWithoutMFA() async throws {
        let http = FakeAuthHTTPClient(responses: [
            .ok(FakeSSOJSON.flow(id: "login-flow-1")),
            .ok(FakeSSOJSON.session(id: "sess-ok", withIdentity: true))
        ])
        let config = makeConfig(autoSendOTP: true)
        let api = SSOAPIClient(http: http, config: config)
        let login = LoginFlowService(api: api, config: config)

        try await login.start()
        let step = try await login.submit(option: .email, identifier: "a@b.com", password: "pw")

        guard case .authenticated(let session, let notices) = step else {
            return XCTFail("expected authenticated, got \(step)")
        }
        XCTAssertEqual(session.id, "sess-ok")
        XCTAssertFalse(session.requiresMFA)
        XCTAssertTrue(notices.isEmpty)
        let recorded = await http.recorded
        XCTAssertEqual(recorded.count, 2)
    }
}
