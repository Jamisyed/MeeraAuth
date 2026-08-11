//
//  Identity.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

public struct Identity: Sendable, Equatable, Codable {
    public let subject: String?
    public let userId: String?
    public let source: String?
    public let username: String?
    public let email: String?
    public let emailVerified: Bool?
    public let mobile: String?
    public let mobileVerified: Bool?
    public let locked: Bool?
    public let firstName: String?
    public let middleName: String?
    public let lastName: String?

    public init(
        subject: String? = nil,
        userId: String? = nil,
        source: String? = nil,
        username: String? = nil,
        email: String? = nil,
        emailVerified: Bool? = nil,
        mobile: String? = nil,
        mobileVerified: Bool? = nil,
        locked: Bool? = nil,
        firstName: String? = nil,
        middleName: String? = nil,
        lastName: String? = nil
    ) {
        self.subject = subject
        self.userId = userId
        self.source = source
        self.username = username
        self.email = email
        self.emailVerified = emailVerified
        self.mobile = mobile
        self.mobileVerified = mobileVerified
        self.locked = locked
        self.firstName = firstName
        self.middleName = middleName
        self.lastName = lastName
    }
}
