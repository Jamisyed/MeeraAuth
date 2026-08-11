//
//  BiometricFlowServiceTests.swift
//  MeeraAuthTests
//

import XCTest
@testable import MeeraAuth

final class BiometricFlowServiceTests: XCTestCase {
    private let config = AuthConfiguration(
        ssoEndpoint: URL(string: "https://sso.test10.meeraspace.com")!,
        ssoXEndpoint: URL(string: "https://sso.test10.meeraspace.com/x")!,
        clientId: .mobileApp,
        scopes: [.openid, .offlineAccess],
        locale: .english,
        loginOptions: [.email],
        resources: TestAuthResources.sample
    )

    func testBiometricLoginAuthenticated() async throws {
        let http = FakeAuthHTTPClient(responses: [
            .ok(FakeSSOJSON.flow(id: "login-flow-1")),
            .ok(FakeSSOJSON.session(id: "sess-bio", withIdentity: true))
        ])
        let api = SSOAPIClient(http: http, config: config)
        let biometric = BiometricFlowService(api: api, config: config)

        try await biometric.startLogin()
        let step = try await biometric.login(
            identifier: "a@b.com",
            name: "HostApp-faceID",
            biometricAuthKey: "uuid-key"
        )

        guard case .authenticated(let session, _) = step else {
            return XCTFail("expected authenticated, got \(step)")
        }
        XCTAssertEqual(session.id, "sess-bio")
        let recorded = await http.recorded
        XCTAssertEqual(recorded.count, 2)
        let body = try JSONSerialization.jsonObject(with: XCTUnwrap(recorded[1].body)) as? [String: Any]
        XCTAssertEqual(body?["method"] as? String, "biometric")
        XCTAssertEqual(body?["biometricAuthKey"] as? String, "uuid-key")
    }

    func testBindAndUnbindBiometricReturnNotices() async throws {
        let http = FakeAuthHTTPClient(responses: [
            .ok(FakeSSOJSON.flow(id: "settings-1")),
            .ok(FakeSSOJSON.flow(
                id: "settings-2",
                messages: [[
                    "code": 2000,
                    "type": "info",
                    "text": "biometric bound"
                ]]
            )),
            .ok(FakeSSOJSON.flow(id: "settings-3")),
            .ok(FakeSSOJSON.flow(
                id: "settings-4",
                messages: [[
                    "code": 2000,
                    "type": "info",
                    "text": "biometric unbound"
                ]]
            ))
        ])
        let api = SSOAPIClient(http: http, config: config)
        let biometric = BiometricFlowService(api: api, config: config)

        try await biometric.startSettings(sessionId: "sess-1", accessToken: nil)
        let bindNotices = try await biometric.bind(
            sessionId: "sess-1",
            identifier: "a@b.com",
            name: "HostApp-faceID",
            biometricAuthKey: "uuid-key"
        )
        XCTAssertEqual(bindNotices.first?.code, .success)

        try await biometric.startSettings(sessionId: "sess-1", accessToken: nil)
        let unbindNotices = try await biometric.unbind(
            sessionId: "sess-1",
            identifier: "a@b.com",
            name: "HostApp-faceID",
            biometricAuthKey: "uuid-key"
        )
        XCTAssertEqual(unbindNotices.first?.code, .success)

        let recorded = await http.recorded
        XCTAssertEqual(recorded.count, 4)
        let bindBody = try JSONSerialization.jsonObject(with: XCTUnwrap(recorded[1].body)) as? [String: Any]
        XCTAssertEqual(bindBody?["method"] as? String, "biometric")
        XCTAssertNil(bindBody?["unlinkKey"])
        let unbindBody = try JSONSerialization.jsonObject(with: XCTUnwrap(recorded[3].body)) as? [String: Any]
        XCTAssertEqual(unbindBody?["unlinkKey"] as? Bool, true)
    }
}
