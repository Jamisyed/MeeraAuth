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

    func testExchangeSavesTokensWhenStoreProvided() async throws {
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

    func testExchangeKeepsMemoryWhenStoreNil() async throws {
        let http = FakeAuthHTTPClient(responses: [
            .ok(FakeSSOJSON.tokens(access: "at-mem", refresh: "rt-mem"))
        ])
        let api = SSOAPIClient(http: http, config: config)
        let tokens = TokenService(api: api, config: config, tokenStore: nil)

        let result = try await tokens.exchange(sessionId: "sess-1")
        XCTAssertEqual(result.accessToken, "at-mem")
        let current = try await tokens.currentTokens()
        XCTAssertEqual(current?.refreshToken, "rt-mem")
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

    func testRefreshUsingHostTokensWithoutPriorMemory() async throws {
        let http = FakeAuthHTTPClient(responses: [
            .ok(FakeSSOJSON.tokens(access: "at-new", refresh: "rt-new"))
        ])
        let api = SSOAPIClient(http: http, config: config)
        let tokens = TokenService(api: api, config: config, tokenStore: nil)

        let saved = TokenSet(accessToken: "at-old", refreshToken: "rt-old", expiresIn: 1, obtainedAt: Date.distantPast)
        let refreshed = try await tokens.refresh(using: saved)

        XCTAssertEqual(refreshed.accessToken, "at-new")
        XCTAssertEqual(refreshed.refreshToken, "rt-new")
        let current = try await tokens.currentTokens()
        XCTAssertEqual(current?.accessToken, "at-new")
    }

    func testRefreshWithRefreshTokenString() async throws {
        let http = FakeAuthHTTPClient(responses: [
            .ok(FakeSSOJSON.tokens(access: "at-rt", refresh: "rt-rotated"))
        ])
        let api = SSOAPIClient(http: http, config: config)
        let tokens = TokenService(api: api, config: config, tokenStore: nil)

        let refreshed = try await tokens.refresh(refreshToken: "rt-only")
        XCTAssertEqual(refreshed.accessToken, "at-rt")
        XCTAssertEqual(refreshed.refreshToken, "rt-rotated")
    }

    func testRestoreThenRefresh() async throws {
        let http = FakeAuthHTTPClient(responses: [
            .ok(FakeSSOJSON.tokens(access: "at-3", refresh: "rt-3"))
        ])
        let api = SSOAPIClient(http: http, config: config)
        let tokens = TokenService(api: api, config: config, tokenStore: nil)

        try await tokens.restore(
            TokenSet(accessToken: "at-saved", refreshToken: "rt-saved", expiresIn: 1, obtainedAt: Date.distantPast)
        )
        let refreshed = try await tokens.refresh()
        XCTAssertEqual(refreshed.accessToken, "at-3")
    }

    func testClearWipesMemoryAndOptionalStore() async throws {
        let http = FakeAuthHTTPClient(responses: [
            .ok(FakeSSOJSON.tokens(access: "at-1", refresh: "rt-1"))
        ])
        let store = InMemoryTokenStore()
        let api = SSOAPIClient(http: http, config: config)
        let tokens = TokenService(api: api, config: config, tokenStore: store)

        _ = try await tokens.exchange(sessionId: "sess-1")
        try await tokens.clear()
        XCTAssertNil(try await tokens.currentTokens())
        XCTAssertNil(try await store.load())
    }
}
