//
//  AuthCivilIdMethodTests.swift
//  MeeraAuthTests
//

import XCTest
@testable import MeeraAuth

final class AuthCivilIdMethodTests: XCTestCase {
    func testRawValues() {
        XCTAssertEqual(AuthCivilIdMethod.civilid.rawValue, "civilid")
        XCTAssertEqual(AuthCivilIdMethod.mafwrInternal.rawValue, "mafwrInternal")
        XCTAssertEqual(AuthCivilIdMethod.custom("otherClient").rawValue, "otherClient")
    }

    func testLoginFlowUsesConfiguredCivilIdMethod() async throws {
        let config = AuthConfiguration(
            ssoEndpoint: URL(string: "https://sso.test10.meeraspace.com")!,
            ssoXEndpoint: URL(string: "https://sso.test10.meeraspace.com/x")!,
            clientId: .mobileApp,
            scopes: [.openid, .offlineAccess],
            locale: .english,
            loginOptions: [.civilId],
            resources: TestAuthResources.sample,
            civilIdMethod: .mafwrInternal
        )
        let http = FakeAuthHTTPClient(responses: [
            .ok(FakeSSOJSON.flow(id: "login-1")),
            .ok(FakeSSOJSON.session(id: "sess-1", withIdentity: true))
        ])
        let api = SSOAPIClient(http: http, config: config)
        let login = LoginFlowService(api: api, config: config)

        try await login.start()
        _ = try await login.submit(option: .civilId, identifier: "1234567", password: "pw")

        let recorded = await http.recorded
        let body = try JSONSerialization.jsonObject(with: XCTUnwrap(recorded[1].body)) as? [String: Any]
        XCTAssertEqual(body?["method"] as? String, "mafwrInternal")
        XCTAssertEqual(body?["civilId"] as? String, "1234567")
    }
}
