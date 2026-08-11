//
//  RecoveryFlowServiceTests.swift
//  MeeraAuthTests
//
//  Created by Syed M Abdul Rehman on 07/08/2026.
//

import XCTest
@testable import MeeraAuth

final class RecoveryFlowServiceTests: XCTestCase {
    func testRecoverySendAndVerifyYieldsSession() async throws {
        let config = AuthConfiguration(
            ssoEndpoint: URL(string: "https://sso.test10.meeraspace.com")!,
            ssoXEndpoint: URL(string: "https://sso.test10.meeraspace.com/x")!,
            clientId: .mobileApp,
            scopes: [.openid],
            locale: .english,
            loginOptions: [.email],
            resources: TestAuthResources.sample
        )
        let http = FakeAuthHTTPClient(responses: [
            .ok(FakeSSOJSON.flow(id: "rec-1")),
            .ok(FakeSSOJSON.flow(
                id: "rec-2",
                flowTokenId: "ft-rec",
                messages: [[
                    "code": 6062,
                    "type": "info",
                    "text": "The code has been send"
                ]]
            )),
            .ok(FakeSSOJSON.session(id: "sess-rec", withIdentity: true))
        ])
        let api = SSOAPIClient(http: http, config: config)
        let recovery = RecoveryFlowService(api: api, config: config)

        try await recovery.start()
        let sent = try await recovery.sendCode(option: .email, identifier: "a@b.com")
        XCTAssertEqual(sent.count, 1)
        XCTAssertEqual(sent[0].code, .codeHasSend)

        let result = try await recovery.verifyCode("123456")
        XCTAssertEqual(result.session.id, "sess-rec")
        let recorded = await http.recorded
        XCTAssertEqual(recorded.count, 3)
        XCTAssertTrue(recorded[0].path.hasSuffix("/recovery/api"))
        XCTAssertEqual(recorded[1].query["flow"], "rec-1")
        XCTAssertEqual(recorded[2].query["flow"], "rec-2")
    }
}
