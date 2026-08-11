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
    public func validAccessToken(skew: TimeInterval = 60) async throws -> String {
        guard let current = try await tokenService.currentTokens() else {
            throw AuthError(code: .noActiveSession, message: "Not signed in")
        }
        if current.isAccessTokenValid(skew: skew) {
            return current.accessToken
        }
        return try await refreshTokens().accessToken
    }

    /// Forces an OAuth refresh against `{sso}/token`. On failure clears session + tokens and emits `.loggedOut`.
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
}
