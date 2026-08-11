//
//  AuthConfigurationValidationTests.swift
//  MeeraAuthTests
//
//  Created by Syed M Abdul Rehman on 07/08/2026.
//

import XCTest
@testable import MeeraAuth

final class AuthConfigurationValidationTests: XCTestCase {
    private let sso = URL(string: "https://sso.test10.meeraspace.com")!
    private let ssoX = URL(string: "https://sso.test10.meeraspace.com/x")!

    private var sampleResources: AuthResourceTemplates {
        TestAuthResources.sample
    }

    func testValidConfigurationHasNoIssues() {
        let config = AuthConfiguration(
            ssoEndpoint: sso,
            ssoXEndpoint: ssoX,
            clientId: .mobileApp,
            scopes: [.openid, .email, .offlineAccess],
            locale: .english,
            loginOptions: [.email],
            resources: sampleResources
        )
        XCTAssertTrue(AuthConfiguration.validationIssues(in: config).isEmpty)
    }

    func testEmptyScopesReported() {
        var config = AuthConfiguration(
            ssoEndpoint: sso,
            ssoXEndpoint: ssoX,
            clientId: .mobileApp,
            scopes: [.openid],
            locale: .english,
            loginOptions: [.email],
            resources: sampleResources
        )
        config.scopes = []
        let issues = AuthConfiguration.validationIssues(in: config)
        XCTAssertTrue(issues.contains(.missingScopes))
    }

    func testEmptyClientIdReported() {
        var config = AuthConfiguration(
            ssoEndpoint: sso,
            ssoXEndpoint: ssoX,
            clientId: .mobileApp,
            scopes: [.openid],
            locale: .english,
            loginOptions: [.email],
            resources: sampleResources
        )
        config.clientId = "  "
        let issues = AuthConfiguration.validationIssues(in: config)
        XCTAssertTrue(issues.contains(.missingClientId))
    }

    func testEmptyLoginOptionsReported() {
        var config = AuthConfiguration(
            ssoEndpoint: sso,
            ssoXEndpoint: ssoX,
            clientId: .mobileApp,
            scopes: [.openid],
            locale: .english,
            loginOptions: [.email],
            resources: sampleResources
        )
        config.loginOptions = []
        let issues = AuthConfiguration.validationIssues(in: config)
        XCTAssertTrue(issues.contains(.missingLoginOptions))
    }

    func testEmptyResourceTemplateReported() {
        var config = AuthConfiguration(
            ssoEndpoint: sso,
            ssoXEndpoint: ssoX,
            clientId: .mobileApp,
            scopes: [.openid],
            locale: .english,
            loginOptions: [.email],
            resources: sampleResources
        )
        config.resources.emailOTP = "  "
        let issues = AuthConfiguration.validationIssues(in: config)
        XCTAssertTrue(issues.contains(.emptyResourceTemplate("emailOTP")))
    }
}
