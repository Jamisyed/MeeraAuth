//
//  SessionStore.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

public protocol SessionStore: Sendable {
    func load() async throws -> Session?
    func save(_ session: Session) async throws
    func clear() async throws
}
