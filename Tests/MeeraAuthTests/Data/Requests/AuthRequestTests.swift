//
//  AuthRequestTests.swift
//  MeeraAuthTests
//
//  Created by Syed M Abdul Rehman on 07/08/2026.
//

import XCTest
@testable import MeeraAuth

final class AuthRequestTests: XCTestCase {
    private let config = AuthConfiguration(
        ssoEndpoint: URL(string: "https://sso.test10.meeraspace.com")!,
        ssoXEndpoint: URL(string: "https://sso.test10.meeraspace.com/x")!,
        clientId: .mobileApp,
        scopes: [.openid, .offlineAccess],
        locale: .english,
        loginOptions: [.email],
        resources: TestAuthResources.sample
    )

    func testLoginStartUsesSSOXGet() throws {
        let http = try LoginRequest.start.makeHTTPRequest(config: config)
        XCTAssertEqual(http.method, "GET")
        XCTAssertEqual(http.url.path, "/x/login/api")
        XCTAssertNil(http.body)
        XCTAssertEqual(http.headers["Accept"], "application/json")
    }

    func testRegistrationStartAndCivilIdPasswordBody() throws {
        let start = try RegistrationRequest.start.makeHTTPRequest(config: config)
        XCTAssertEqual(start.method, "GET")
        XCTAssertEqual(start.url.path, "/x/registration/api")

        let submit = try RegistrationRequest.submitCivilIdPassword(
            flowId: "reg-1",
            password: "pw",
            confirmPassword: "pw",
            method: "civilid"
        ).makeHTTPRequest(config: config)
        XCTAssertEqual(submit.method, "POST")
        XCTAssertEqual(submit.url.path, "/x/registration")
        XCTAssertEqual(submit.url.query, "flow=reg-1")
        let json = try JSONSerialization.jsonObject(with: XCTUnwrap(submit.body)) as? [String: Any]
        XCTAssertEqual(json?["method"] as? String, "civilid")
        XCTAssertEqual(json?["password"] as? String, "pw")
    }

    func testLoginSubmitBuildsJSONBodyAndFlowQuery() throws {
        let http = try LoginRequest.submit(
            flowId: "flow-1",
            option: .email,
            identifier: "a@b.com",
            password: "secret",
            method: "password"
        ).makeHTTPRequest(config: config)

        XCTAssertEqual(http.method, "POST")
        XCTAssertEqual(http.url.path, "/x/login")
        XCTAssertEqual(http.url.query, "flow=flow-1")
        XCTAssertEqual(http.headers["Content-Type"], "application/json")

        let body = try XCTUnwrap(http.body)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["email"] as? String, "a@b.com")
        XCTAssertEqual(json["method"] as? String, "password")
        XCTAssertEqual(json["password"] as? String, "secret")
    }

    func testBiometricLoginAndSettingsBodies() throws {
        let login = try LoginRequest.submitBiometric(
            flowId: "flow-bio",
            identifier: "a@b.com",
            name: "HostApp-faceID",
            biometricAuthKey: "uuid-key"
        ).makeHTTPRequest(config: config)
        XCTAssertEqual(login.url.path, "/x/login")
        XCTAssertEqual(login.url.query, "flow=flow-bio")
        let loginJSON = try XCTUnwrap(
            JSONSerialization.jsonObject(with: XCTUnwrap(login.body)) as? [String: Any]
        )
        XCTAssertEqual(loginJSON["method"] as? String, "biometric")
        XCTAssertEqual(loginJSON["identifier"] as? String, "a@b.com")
        XCTAssertEqual(loginJSON["name"] as? String, "HostApp-faceID")
        XCTAssertEqual(loginJSON["biometricAuthKey"] as? String, "uuid-key")

        let bind = try SettingsRequest.bindBiometric(
            flowId: "settings-1",
            sessionId: "sess-1",
            identifier: "a@b.com",
            name: "HostApp-faceID",
            biometricAuthKey: "uuid-key"
        ).makeHTTPRequest(config: config)
        XCTAssertEqual(bind.url.path, "/x/settings")
        XCTAssertEqual(bind.url.query, "flow=settings-1")
        XCTAssertEqual(bind.headers["X-SESSION-ID"], "sess-1")
        let bindJSON = try XCTUnwrap(
            JSONSerialization.jsonObject(with: XCTUnwrap(bind.body)) as? [String: Any]
        )
        XCTAssertEqual(bindJSON["method"] as? String, "biometric")
        XCTAssertNil(bindJSON["unlinkKey"])

        let unbind = try SettingsRequest.unbindBiometric(
            flowId: "settings-1",
            sessionId: "sess-1",
            identifier: "a@b.com",
            name: "HostApp-faceID",
            biometricAuthKey: "uuid-key"
        ).makeHTTPRequest(config: config)
        let unbindJSON = try XCTUnwrap(
            JSONSerialization.jsonObject(with: XCTUnwrap(unbind.body)) as? [String: Any]
        )
        XCTAssertEqual(unbindJSON["unlinkKey"] as? Bool, true)
        XCTAssertEqual(unbindJSON["method"] as? String, "biometric")
    }

    func testLoginCivilIdUsesConfiguredMethod() throws {
        let http = try LoginRequest.submit(
            flowId: "flow-1",
            option: .civilId,
            identifier: "1234567",
            password: "secret",
            method: AuthCivilIdMethod.mafwrInternal.rawValue
        ).makeHTTPRequest(config: config)

        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: XCTUnwrap(http.body)) as? [String: Any]
        )
        XCTAssertEqual(json["civilId"] as? String, "1234567")
        XCTAssertEqual(json["method"] as? String, "mafwrInternal")
        XCTAssertEqual(json["password"] as? String, "secret")
    }

    func testTokenExchangeUsesFormOnSSOXWithSession() throws {
        let http = try TokenRequest.exchange(
            sessionId: "sess-1",
            clientId: "mobile-app",
            scope: "openid offline_access"
        ).makeHTTPRequest(config: config)

        XCTAssertEqual(http.method, "POST")
        XCTAssertEqual(http.url.path, "/x/token/exchange")
        XCTAssertEqual(http.headers["X-SESSION-ID"], "sess-1")
        XCTAssertEqual(http.headers["Content-Type"], "application/x-www-form-urlencoded")
        let body = String(data: try XCTUnwrap(http.body), encoding: .utf8) ?? ""
        XCTAssertTrue(body.contains("client_id=mobile-app"))
        XCTAssertTrue(body.contains("scope=openid"))
    }

    func testTokenRefreshUsesSSORoot() throws {
        let http = try TokenRequest.refresh(
            clientId: "mobile-app",
            refreshToken: "rt-1",
            scope: "openid"
        ).makeHTTPRequest(config: config)

        XCTAssertEqual(http.url.path, "/token")
        XCTAssertFalse(http.url.path.contains("/x/"))
        XCTAssertEqual(http.url.host, "sso.test10.meeraspace.com")
        let body = String(data: try XCTUnwrap(http.body), encoding: .utf8) ?? ""
        XCTAssertTrue(body.contains("grant_type=refresh_token"))
        XCTAssertTrue(body.contains("refresh_token=rt-1"))
    }

    func testLogoutUsesDeleteOnSSOWithBearer() throws {
        let http = try LogoutRequest.logout(accessToken: "tok").makeHTTPRequest(config: config)
        XCTAssertEqual(http.method, "DELETE")
        XCTAssertEqual(http.url.path, "/logout/api")
        XCTAssertEqual(http.headers["Authorization"], "Bearer tok")
    }
}
