//
//  TokenSet.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

public struct TokenSet: Sendable, Equatable, Codable {
    public let accessToken: String
    public let refreshToken: String?
    public let idToken: String?
    public let tokenType: String?
    public let expiresIn: TimeInterval?
    public let obtainedAt: Date

    public var accessTokenExpiresAt: Date? {
        guard let expiresIn else { return nil }
        return obtainedAt.addingTimeInterval(expiresIn)
    }

    /// `true` when the access token is usable, allowing `skew` seconds of clock / network margin.
    /// When `expires_in` was never provided, returns `true` (host should force-refresh on 401).
    public func isAccessTokenValid(skew: TimeInterval = 60, now: Date = Date()) -> Bool {
        guard let expiresAt = accessTokenExpiresAt else { return true }
        return expiresAt > now.addingTimeInterval(skew)
    }

    public init(
        accessToken: String,
        refreshToken: String? = nil,
        idToken: String? = nil,
        tokenType: String? = "bearer",
        expiresIn: TimeInterval? = nil,
        obtainedAt: Date = Date()
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.idToken = idToken
        self.tokenType = tokenType
        self.expiresIn = expiresIn
        self.obtainedAt = obtainedAt
    }

    /// Merges a refresh response with the previous set (SSO may omit rotating refresh / id tokens).
    public func mergingRefreshResponse(_ refreshed: TokenSet) -> TokenSet {
        TokenSet(
            accessToken: refreshed.accessToken,
            refreshToken: refreshed.refreshToken ?? refreshToken,
            idToken: refreshed.idToken ?? idToken,
            tokenType: refreshed.tokenType ?? tokenType,
            expiresIn: refreshed.expiresIn ?? expiresIn,
            obtainedAt: refreshed.obtainedAt
        )
    }

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case idToken = "id_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case obtainedAt
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try c.decode(String.self, forKey: .accessToken)
        refreshToken = try c.decodeIfPresent(String.self, forKey: .refreshToken)
        idToken = try c.decodeIfPresent(String.self, forKey: .idToken)
        tokenType = try c.decodeIfPresent(String.self, forKey: .tokenType)
        if let intExp = try? c.decodeIfPresent(Int.self, forKey: .expiresIn) {
            expiresIn = TimeInterval(intExp)
        } else {
            expiresIn = try c.decodeIfPresent(TimeInterval.self, forKey: .expiresIn)
        }
        obtainedAt = try c.decodeIfPresent(Date.self, forKey: .obtainedAt) ?? Date()
    }
}
