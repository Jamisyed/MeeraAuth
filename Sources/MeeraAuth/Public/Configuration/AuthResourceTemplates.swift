//
//  AuthResourceTemplates.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

public struct AuthResourceTemplates: Sendable, Equatable {
    public var emailOTP: String
    public var mobileOTP: String
    public var resetEmail: String
    public var resetMobile: String
    public var activeEmail: String
    public var activeMobile: String

    public init(
        emailOTP: String,
        mobileOTP: String,
        resetEmail: String,
        resetMobile: String,
        activeEmail: String,
        activeMobile: String
    ) {
        self.emailOTP = emailOTP
        self.mobileOTP = mobileOTP
        self.resetEmail = resetEmail
        self.resetMobile = resetMobile
        self.activeEmail = activeEmail
        self.activeMobile = activeMobile
    }

    public func injecting(locale: AuthLocale) -> AuthResourceTemplates {
        AuthResourceTemplates(
            emailOTP: Self.injectLocale(into: emailOTP, locale: locale),
            mobileOTP: Self.injectLocale(into: mobileOTP, locale: locale),
            resetEmail: Self.injectLocale(into: resetEmail, locale: locale),
            resetMobile: Self.injectLocale(into: resetMobile, locale: locale),
            activeEmail: Self.injectLocale(into: activeEmail, locale: locale),
            activeMobile: Self.injectLocale(into: activeMobile, locale: locale)
        )
    }

    public static func injectLocale(into template: String, locale: AuthLocale) -> String {
        let prefix = "{sso}"
        guard template.hasPrefix(prefix) else {
            return template
        }
        let remainder = String(template.dropFirst(prefix.count))
        for code in AuthLocale.allCases.map(\.rawValue) where remainder.hasPrefix("{\(code)}") {
            return template
        }
        return "\(prefix){\(locale.rawValue)}\(remainder)"
    }
}
