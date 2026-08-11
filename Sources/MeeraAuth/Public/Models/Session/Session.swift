//
//  Session.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

public struct Session: Sendable, Equatable, Codable {
    public let id: String
    public let userId: String?
    public let active: Bool?
    public let expiresAt: Date?
    public let authenticatedAt: Date?
    public let authenticatorAssuranceLevel: String?
    public let identity: Identity?

    public var requiresMFA: Bool { identity == nil }

    public init(
        id: String,
        userId: String? = nil,
        active: Bool? = nil,
        expiresAt: Date? = nil,
        authenticatedAt: Date? = nil,
        authenticatorAssuranceLevel: String? = nil,
        identity: Identity? = nil
    ) {
        self.id = id
        self.userId = userId
        self.active = active
        self.expiresAt = expiresAt
        self.authenticatedAt = authenticatedAt
        self.authenticatorAssuranceLevel = authenticatorAssuranceLevel
        self.identity = identity
    }
}
