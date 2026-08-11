//
//  TokenService.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

protocol TokenServing: Sendable {
    func exchange(sessionId: String) async throws -> TokenSet
    func refresh() async throws -> TokenSet
    func currentTokens() async throws -> TokenSet?
    func clear() async throws
}

actor TokenService: TokenServing {
    private let api: SSOAPIClient
    private let config: AuthConfiguration
    private let tokenStore: any TokenStore
    private var refreshTask: Task<TokenSet, Error>?

    init(api: SSOAPIClient, config: AuthConfiguration, tokenStore: any TokenStore) {
        self.api = api
        self.config = config
        self.tokenStore = tokenStore
    }

    func exchange(sessionId: String) async throws -> TokenSet {
        let response = try await api.execute(
            TokenRequest.exchange(
                sessionId: sessionId,
                clientId: config.clientId,
                scope: config.scopes.asSpaceSeparatedString
            )
        )
        guard (200..<300).contains(response.statusCode) else {
            throw AuthError.network("Token exchange failed", status: response.statusCode)
        }
        let tokens = try JSONDecoder().decode(TokenSet.self, from: response.data)
        try await tokenStore.save(tokens)
        return tokens
    }

    /// OAuth2 refresh_token grant against `{ssoEndpoint}/token`.
    /// Concurrent callers share a single in-flight request.
    func refresh() async throws -> TokenSet {
        if let refreshTask {
            return try await refreshTask.value
        }

        let task = Task {
            try await self.performRefresh()
        }
        refreshTask = task
        do {
            let tokens = try await task.value
            refreshTask = nil
            return tokens
        } catch {
            refreshTask = nil
            throw error
        }
    }

    func currentTokens() async throws -> TokenSet? {
        try await tokenStore.load()
    }

    func clear() async throws {
        refreshTask?.cancel()
        refreshTask = nil
        try await tokenStore.clear()
    }

    // MARK: - Private

    private func performRefresh() async throws -> TokenSet {
        guard let current = try await tokenStore.load() else {
            throw AuthError(code: .noActiveSession, message: "Not signed in")
        }
        guard let refreshToken = current.refreshToken, !refreshToken.isEmpty else {
            throw AuthError(
                code: .noActiveSession,
                message: "No refresh token — include .offlineAccess in scopes and re-authenticate"
            )
        }

        var scope: String? = config.scopes.asSpaceSeparatedString
        if scope?.isEmpty == true {
            scope = nil
        }

        let response = try await api.execute(
            TokenRequest.refresh(
                clientId: config.clientId,
                refreshToken: refreshToken,
                scope: scope
            )
        )
        guard (200..<300).contains(response.statusCode) else {
            let code: AuthErrorCode = (response.statusCode == 401 || response.statusCode == 403)
                ? .unauthorized
                : .tokenExpired
            throw AuthError(
                code: code,
                message: "Token refresh failed",
                httpStatus: response.statusCode
            )
        }

        let decoded = try JSONDecoder().decode(TokenSet.self, from: response.data)
        let tokens = current.mergingRefreshResponse(decoded)
        try await tokenStore.save(tokens)
        return tokens
    }
}
