//
//  AuthConfiguration.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

public struct AuthConfiguration: Sendable {
    public var ssoEndpoint: URL
    public var ssoXEndpoint: URL
    public var clientId: String
    public var scopes: [AuthScope]
    public var locale: AuthLocale
    public var loginOptions: Set<LoginOption>
    public var signupOptions: Set<SignupOption>
    public var resources: AuthResourceTemplates
    public var civilIdMethod: AuthCivilIdMethod
    public var mfaPolicy: MFAPolicy
    public var networkLogging: AuthNetworkLogging

    public init(
        ssoEndpoint: URL,
        ssoXEndpoint: URL,
        clientId: AuthClientID,
        scopes: [AuthScope],
        locale: AuthLocale,
        loginOptions: Set<LoginOption>,
        signupOptions: Set<SignupOption> = [],
        resources: AuthResourceTemplates,
        civilIdMethod: AuthCivilIdMethod = .civilid,
        mfaPolicy: MFAPolicy = MFAPolicy(),
        networkLogging: AuthNetworkLogging = .off
    ) {
        self.init(
            ssoEndpoint: ssoEndpoint,
            ssoXEndpoint: ssoXEndpoint,
            clientId: clientId.rawValue,
            scopes: scopes,
            locale: locale,
            loginOptions: loginOptions,
            signupOptions: signupOptions,
            resources: resources,
            civilIdMethod: civilIdMethod,
            mfaPolicy: mfaPolicy,
            networkLogging: networkLogging
        )
    }

    public init(
        ssoEndpoint: URL,
        ssoXEndpoint: URL,
        clientId: String,
        scopes: [AuthScope],
        locale: AuthLocale,
        loginOptions: Set<LoginOption>,
        signupOptions: Set<SignupOption> = [],
        resources: AuthResourceTemplates,
        civilIdMethod: AuthCivilIdMethod = .civilid,
        mfaPolicy: MFAPolicy = MFAPolicy(),
        networkLogging: AuthNetworkLogging = .off
    ) {
        self.ssoEndpoint = ssoEndpoint
        self.ssoXEndpoint = ssoXEndpoint
        self.clientId = clientId
        self.scopes = scopes
        self.locale = locale
        self.loginOptions = loginOptions
        self.signupOptions = signupOptions
        self.resources = resources
        self.civilIdMethod = civilIdMethod
        self.mfaPolicy = mfaPolicy
        self.networkLogging = networkLogging
        AuthConfiguration.assertValid(self)
    }

    public var resolvedResources: AuthResourceTemplates {
        resources.injecting(locale: locale)
    }

    public static func validationIssues(in configuration: AuthConfiguration) -> [AuthConfigurationIssue] {
        var issues: [AuthConfigurationIssue] = []

        if configuration.clientId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.missingClientId)
        }
        if configuration.scopes.isEmpty {
            issues.append(.missingScopes)
        }
        if configuration.loginOptions.isEmpty {
            issues.append(.missingLoginOptions)
        }
        if !isAcceptableSSOURL(configuration.ssoEndpoint) {
            issues.append(.invalidSSOEndpoint(configuration.ssoEndpoint))
        }
        if !isAcceptableSSOURL(configuration.ssoXEndpoint) {
            issues.append(.invalidSSOXEndpoint(configuration.ssoXEndpoint))
        }

        let resources = configuration.resources
        let resourceValues = [
            ("emailOTP", resources.emailOTP),
            ("mobileOTP", resources.mobileOTP),
            ("resetEmail", resources.resetEmail),
            ("resetMobile", resources.resetMobile),
            ("activeEmail", resources.activeEmail),
            ("activeMobile", resources.activeMobile)
        ]
        for (name, value) in resourceValues where value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.emptyResourceTemplate(name))
        }

        return issues
    }

    public static func assertValid(_ configuration: AuthConfiguration) {
        let issues = validationIssues(in: configuration)
        guard !issues.isEmpty else { return }
        let detail = issues.map(\.message).joined(separator: "\n - ")
        preconditionFailure(
            """
            MeeraAuth AuthConfiguration is invalid — fix the host bootstrap before shipping:
             - \(detail)
            """
        )
    }

    private static func isAcceptableSSOURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        guard scheme == "https" || scheme == "http" else { return false }
        guard let host = url.host, !host.isEmpty else { return false }
        return true
    }
}
