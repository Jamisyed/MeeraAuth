//
//  AuthResourceTemplatesTests.swift
//  MeeraAuthTests
//
//  Created by Syed M Abdul Rehman on 07/08/2026.
//

import XCTest
@testable import MeeraAuth

final class AuthResourceTemplatesTests: XCTestCase {
    func testInjectsLocaleAfterSSOPrefix() {
        XCTAssertEqual(
            AuthResourceTemplates.injectLocale(into: "{sso}{emailOtpTmpl}", locale: .english),
            "{sso}{en}{emailOtpTmpl}"
        )
        XCTAssertEqual(
            AuthResourceTemplates.injectLocale(into: "{sso}{emailOtpTmpl}", locale: .arabic),
            "{sso}{ar}{emailOtpTmpl}"
        )
    }

    func testDoesNotDoubleInjectKnownLocale() {
        XCTAssertEqual(
            AuthResourceTemplates.injectLocale(into: "{sso}{en}{emailOtpTmpl}", locale: .arabic),
            "{sso}{en}{emailOtpTmpl}"
        )
    }

    func testLeavesNonSSOTemplatesUnchanged() {
        XCTAssertEqual(
            AuthResourceTemplates.injectLocale(into: "custom-template", locale: .english),
            "custom-template"
        )
    }

    func testResolvedResourcesInjectConfigurationLocale() {
        let resources = TestAuthResources.sample
        let config = AuthConfiguration(
            ssoEndpoint: URL(string: "https://sso.test10.meeraspace.com")!,
            ssoXEndpoint: URL(string: "https://sso.test10.meeraspace.com/x")!,
            clientId: .mobileApp,
            scopes: [.openid],
            locale: .arabic,
            loginOptions: [.email],
            resources: resources
        )
        XCTAssertEqual(config.resources, resources)
        XCTAssertEqual(config.resolvedResources.emailOTP, "{sso}{ar}{emailOtpTmpl}")
        XCTAssertEqual(config.resolvedResources.mobileOTP, "{sso}{ar}{mobileOtpTmpl}")
        XCTAssertEqual(config.resolvedResources.resetEmail, "{sso}{ar}{resetEmailTmpl}")
        XCTAssertEqual(config.resolvedResources.resetMobile, "{sso}{ar}{resetMobileTmpl}")
        XCTAssertEqual(config.resolvedResources.activeEmail, "{sso}{ar}{activeEmailTmpl}")
        XCTAssertEqual(config.resolvedResources.activeMobile, "{sso}{ar}{activeMobileTmpl}")
    }
}
