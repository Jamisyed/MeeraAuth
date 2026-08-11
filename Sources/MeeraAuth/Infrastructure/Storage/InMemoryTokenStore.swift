//
//  InMemoryTokenStore.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

public actor InMemoryTokenStore: TokenStore {
    private var tokens: TokenSet?

    public init() {}

    public func load() async throws -> TokenSet? { tokens }
    public func save(_ tokens: TokenSet) async throws { self.tokens = tokens }
    public func clear() async throws { tokens = nil }
}
