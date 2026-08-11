//
//  TokenStore.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

public protocol TokenStore: Sendable {
    func load() async throws -> TokenSet?
    func save(_ tokens: TokenSet) async throws
    func clear() async throws
}
