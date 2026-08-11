//
//  RegistrationProfile.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 06/08/2026.
//

import Foundation

public struct RegistrationProfile: Sendable, Equatable {
    public var email: String
    public var mobile: String
    public var username: String
    public var firstName: String
    public var middleName: String
    public var lastName: String
    public var password: String
    public var confirmPassword: String

    public init(
        email: String = "",
        mobile: String = "",
        username: String = "",
        firstName: String = "",
        middleName: String = "",
        lastName: String = "",
        password: String,
        confirmPassword: String
    ) {
        self.email = email
        self.mobile = mobile
        self.username = username
        self.firstName = firstName
        self.middleName = middleName
        self.lastName = lastName
        self.password = password
        self.confirmPassword = confirmPassword
    }
}
