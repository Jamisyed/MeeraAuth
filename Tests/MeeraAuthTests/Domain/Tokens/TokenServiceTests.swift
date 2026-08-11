//
//  TokenServiceTests.swift
//  MeeraAuthTests
//
//  Created by Syed M Abdul Rehman on 07/08/2026.
//

import XCTest
@testable import MeeraAuth

final class TokenServiceTests: XCTestCase {
    private let config = AuthConfiguration(
        ssoEndpoint: URL(string: "https://sso.test10.meeraspace.com")!,
        ssoXEndpoint: URL(string: "https://sso.test10.meeraspace.com/x")!,
        clientId: .mobileApp,
        scopes: [.openid, .offlineAccess],
        locale: .english,
        loginOptions: [.email],
        resources: TestAuthResources.sample
    )

    func testExchangeSavesTokens() async throws {
        let http = FakeAuthHTTPClient(responses: [
            .ok(FakeSSOJSON.tokens(access: "at-1", refresh: "rt-1"))
        ])
        let store = InMemoryTokenStore()
        let api = SSOAPIClient(http: http, config: config)
        let tokens = TokenService(api: api, config: config, tokenStore: store)

        let result = try await tokens.exchange(sessionId: "sess-1")
        XCTAssertEqual(result.accessToken, "at-1")
        XCTAssertEqual(result.refreshToken, "rt-1")
        let stored = try await store.load()
        XCTAssertEqual(stored?.accessToken, "at-1")

        let recorded = await http.recorded
        XCTAssertEqual(recorded.count, 1)
        XCTAssertTrue(recorded[0].path.hasSuffix("/token/exchange"))
        XCTAssertEqual(recorded[0].headers["X-SESSION-ID"], "sess-1")
        XCTAssertEqual(recorded[0].headers["Content-Type"], "application/x-www-form-urlencoded")
    }

    func testRefreshSingleFlightSharesOneRequest() async throws {
        let http = FakeAuthHTTPClient(responses: [
            .ok(FakeSSOJSON.tokens(access: "at-2", refresh: "rt-2"))
        ])
        let store = InMemoryTokenStore()
        try await store.save(
            TokenSet(accessToken: "at-old", refreshToken: "rt-old", expiresIn: 1, obtainedAt: Date.distantPast)
        )
        let api = SSOAPIClient(http: http, config: config)
        let tokens = TokenService(api: api, config: config, tokenStore: store)

        async let a = tokens.refresh()
        async let b = tokens.refresh()
        let (t1, t2) = try await (a, b)

        XCTAssertEqual(t1.accessToken, "at-2")
        XCTAssertEqual(t2.accessToken, "at-2")
        let recorded = await http.recorded
        XCTAssertEqual(recorded.count, 1, "concurrent refresh should single-flight")
        XCTAssertTrue(recorded[0].path.hasSuffix("/token"))
        XCTAssertFalse(recorded[0].path.contains("/x/"))
    }
}
