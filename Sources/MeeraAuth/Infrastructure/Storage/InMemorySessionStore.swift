//
//  InMemorySessionStore.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

public actor InMemorySessionStore: SessionStore {
    private var session: Session?

    public init() {}

    public func load() async throws -> Session? { session }
    public func save(_ session: Session) async throws { self.session = session }
    public func clear() async throws { session = nil }
}
