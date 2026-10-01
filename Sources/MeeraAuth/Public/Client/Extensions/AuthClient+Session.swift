//
//  AuthClient+Session.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 06/08/2026.
//

import Foundation

extension AuthClient {
    // MARK: - Session / tokens

    public func currentSession() async throws -> Session? {
        try await sessionStore.load()
    }

    public func currentTokens() async throws -> TokenSet? {
        try await tokenService.currentTokens()
    }

    public func accessToken() async throws -> String? {
        try await tokenService.currentTokens()?.accessToken
    }

    /// Returns a usable access token. Refreshes via OAuth `refresh_token` when expired
    /// (or within `skew` seconds of expiry). Prefer this over `accessToken()` for API calls.
    ///
    /// Requires tokens already in memory (after `exchangeTokens` / `restoreTokens` /
    /// `refreshTokens(using:)`) or in an injected `tokenStore`.
    public func validAccessToken(skew: TimeInterval = 60) async throws -> String {
        guard let current = try await tokenService.currentTokens() else {
            throw AuthError(code: .noActiveSession, message: "Not signed in")
        }
        if current.isAccessTokenValid(skew: skew) {
            return current.accessToken
        }
        return try await refreshTokens().accessToken
    }

    /// Restore host-persisted tokens into AuthClient memory (and optional `tokenStore`).
    /// Call after cold start when `tokenStore` was `nil` and the host saved tokens itself.
    public func restoreTokens(_ tokens: TokenSet) async throws {
        try await tokenService.restore(tokens)
        emit(.tokensUpdated(tokens))
    }

    /// Forces an OAuth refresh using tokens already in memory / optional store.
    /// On failure clears session + tokens and emits `.loggedOut`.
    @discardableResult
    public func refreshTokens() async throws -> TokenSet {
        do {
            let tokens = try await tokenService.refresh()
            emit(.tokensUpdated(tokens))
            return tokens
        } catch {
            try? await sessionStore.clear()
            try? await tokenService.clear()
            emit(.loggedOut)
            throw error
        }
    }

    /// Cold start / host-owned storage: pass saved `TokenSet`, refresh, return new set for host to save.
    @discardableResult
    public func refreshTokens(using tokens: TokenSet) async throws -> TokenSet {
        do {
            let refreshed = try await tokenService.refresh(using: tokens)
            emit(.tokensUpdated(refreshed))
            return refreshed
        } catch {
            try? await sessionStore.clear()
            try? await tokenService.clear()
            emit(.loggedOut)
            throw error
        }
    }

    /// Cold start when the host only persisted the refresh token string.
    @discardableResult
    public func refreshTokens(refreshToken: String) async throws -> TokenSet {
        do {
            let refreshed = try await tokenService.refresh(refreshToken: refreshToken)
            emit(.tokensUpdated(refreshed))
            return refreshed
        } catch {
            try? await sessionStore.clear()
            try? await tokenService.clear()
            emit(.loggedOut)
            throw error
        }
    }
}
