//
//  RegistrationFlowServiceTests.swift
//  MeeraAuthTests
//
//  Created by Syed M Abdul Rehman on 07/08/2026.
//

import XCTest
@testable import MeeraAuth

final class RegistrationFlowServiceTests: XCTestCase {
    private let config = AuthConfiguration(
        ssoEndpoint: URL(string: "https://sso.test10.meeraspace.com")!,
        ssoXEndpoint: URL(string: "https://sso.test10.meeraspace.com/x")!,
        clientId: .mobileApp,
        scopes: [.openid, .offlineAccess],
        locale: .english,
        loginOptions: [.email, .civilId],
        signupOptions: [.basic, .civilId],
        resources: TestAuthResources.sample
    )

    func testBasicRegisterRequiresVerification() async throws {
        let http = FakeAuthHTTPClient(responses: [
            .ok(FakeSSOJSON.flow(id: "reg-1")),
            .ok(FakeSSOJSON.verificationHandoffFlow(id: "verify-1", flowTokenId: "ft-v"))
        ])
        let api = SSOAPIClient(http: http, config: config)
        let registration = RegistrationFlowService(api: api, config: config)

        try await registration.start()
        let outcome = try await registration.submitPassword(
            RegistrationProfile(email: "a@b.com", username: "user", password: "pw", confirmPassword: "pw")
        )

        guard case let .requiresVerification(flowId, flowTokenId) = outcome else {
            return XCTFail("expected requiresVerification, got \(outcome)")
        }
        XCTAssertEqual(flowId, "verify-1")
        XCTAssertEqual(flowTokenId, "ft-v")

        let recorded = await http.recorded
        XCTAssertEqual(recorded.count, 2)
        XCTAssertTrue(recorded[0].path.hasSuffix("/registration/api"))
        XCTAssertTrue(recorded[1].path.hasSuffix("/registration"))
        XCTAssertEqual(recorded[1].query["flow"], "reg-1")
        let body = try XCTUnwrap(recorded[1].body)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        XCTAssertEqual(json?["method"] as? String, "password")
        XCTAssertEqual(json?["email"] as? String, "a@b.com")
        XCTAssertEqual(json?["resource"] as? String, "{sso}{en}{activeEmailTmpl}")
    }

    func testCivilIdHappyPathCompletesWithIdentity() async throws {
        let http = FakeAuthHTTPClient(responses: [
            .ok(FakeSSOJSON.flow(id: "reg-1")),
            .ok(FakeSSOJSON.flow(
                id: "reg-1",
                username: "ABDULLAH en2",
                messages: [[
                    "code": 2000,
                    "type": "info",
                    "text": "CivilID has been verified, you can use this civilID to continue registration.",
                    "context": ["civilID": "1234567"]
                ]]
            )),
            .ok(FakeSSOJSON.flow(id: "reg-1", flowTokenId: "ft-m")),
            .ok(FakeSSOJSON.flow(id: "reg-1", flowTokenId: "ft-m2")),
            .ok(FakeSSOJSON.flow(id: "reg-1", flowTokenId: "ft-e")),
            .ok(FakeSSOJSON.flow(id: "reg-1", flowTokenId: "ft-e2")),
            .ok(FakeSSOJSON.identityCompleted())
        ])
        let api = SSOAPIClient(http: http, config: config)
        let registration = RegistrationFlowService(api: api, config: config)

        try await registration.start()
        let civil = try await registration.verifyCivilId("1234567", expiry: "2026-01-01")
        XCTAssertEqual(civil.username, "ABDULLAH en2")
        XCTAssertEqual(civil.notices.count, 1)
        XCTAssertEqual(civil.notices[0].code, .success)
        XCTAssertEqual(civil.notices[0].context["civilID"], "1234567")
        _ = try await registration.sendMobileOTP(mobile: "+96890000000", username: nil, useCivilIDMobile: true)
        _ = try await registration.verifyMobileOTP("1111")
        _ = try await registration.sendEmailOTP("a@b.com")
        _ = try await registration.verifyEmailOTP("2222")
        let outcome = try await registration.submitCivilIdPassword(password: "pw", confirmPassword: "pw")

        guard case .completed(nil) = outcome else {
            return XCTFail("expected completed(nil), got \(outcome)")
        }

        let recorded = await http.recorded
        XCTAssertEqual(recorded.count, 7)
        let mobileSendBody = try JSONSerialization.jsonObject(with: XCTUnwrap(recorded[2].body)) as? [String: Any]
        XCTAssertEqual(mobileSendBody?["username"] as? String, "ABDULLAH en2")
        let mobileVerifyBody = try JSONSerialization.jsonObject(with: XCTUnwrap(recorded[3].body)) as? [String: Any]
        XCTAssertEqual(mobileVerifyBody?["code"] as? String, "1111")
        XCTAssertEqual(mobileVerifyBody?["resource"] as? String, "{sso}{en}{activeMobileTmpl}")
        let emailSendBody = try JSONSerialization.jsonObject(with: XCTUnwrap(recorded[4].body)) as? [String: Any]
        XCTAssertEqual(emailSendBody?["email"] as? String, "a@b.com")
        XCTAssertNil(emailSendBody?["flowTokenId"], "Tawteen first email send omits flowTokenId")
        let emailVerifyBody = try JSONSerialization.jsonObject(with: XCTUnwrap(recorded[5].body)) as? [String: Any]
        XCTAssertEqual(emailVerifyBody?["code"] as? String, "2222")
        XCTAssertEqual(emailVerifyBody?["resource"] as? String, "{sso}{en}{activeEmailTmpl}")
        XCTAssertEqual(emailVerifyBody?["method"] as? String, "civilid")
        XCTAssertEqual(emailVerifyBody?["flowTokenId"] as? String, "ft-e")
        let passwordBody = try JSONSerialization.jsonObject(with: XCTUnwrap(recorded[6].body)) as? [String: Any]
        XCTAssertEqual(passwordBody?["method"] as? String, "civilid")
        XCTAssertEqual(passwordBody?["password"] as? String, "pw")
    }

    func testIdentityAlreadyExistsMapsError() async throws {
        let http = FakeAuthHTTPClient(responses: [
            .ok(FakeSSOJSON.flow(id: "reg-1")),
            .badRequest(FakeSSOJSON.flowError(id: "reg-1", code: 6047, text: "Identity already exists"))
        ])
        let api = SSOAPIClient(http: http, config: config)
        let registration = RegistrationFlowService(api: api, config: config)

        try await registration.start()
        do {
            _ = try await registration.submitPassword(
                RegistrationProfile(email: "a@b.com", password: "pw", confirmPassword: "pw")
            )
            XCTFail("expected throw")
        } catch let error as AuthError {
            XCTAssertEqual(error.code, .identityAlreadyExists)
            XCTAssertEqual(error.field, .email)
        }
    }

    func testInvalidCivilIdMapsError() async throws {
        let http = FakeAuthHTTPClient(responses: [
            .ok(FakeSSOJSON.flow(id: "reg-1")),
            .badRequest(FakeSSOJSON.flowError(id: "reg-1", code: 6077, text: "Invalid Civil ID"))
        ])
        let api = SSOAPIClient(http: http, config: config)
        let registration = RegistrationFlowService(api: api, config: config)

        try await registration.start()
        do {
            try await registration.verifyCivilId("bad", expiry: "2020-01-01")
            XCTFail("expected throw")
        } catch let error as AuthError {
            XCTAssertEqual(error.code, .invalidCivilID)
            XCTAssertEqual(error.field, .civilId)
        }
    }

    func testAuthClientSeedsVerificationAfterBasicRegister() async throws {
        let http = FakeAuthHTTPClient(responses: [
            .ok(FakeSSOJSON.flow(id: "reg-1")),
            .ok(FakeSSOJSON.verificationHandoffFlow(id: "verify-seeded", flowTokenId: "ft-seed")),
            .ok(FakeSSOJSON.flow(id: "verify-seeded", flowTokenId: "ft-after-send"))
        ])
        let auth = AuthClient(
            configuration: config,
            httpClient: http,
            sessionStore: InMemorySessionStore(),
            tokenStore: InMemoryTokenStore()
        )

        try await auth.startRegistration()
        let step = try await auth.register(
            RegistrationProfile(email: "a@b.com", password: "pw", confirmPassword: "pw")
        )
        XCTAssertEqual(step, .requiresVerification)

        try await auth.verificationSendOTP(channel: .email, identifier: "a@b.com")
        let recorded = await http.recorded
        XCTAssertEqual(recorded.count, 3)
        XCTAssertTrue(recorded[2].path.hasSuffix("/verification"))
        XCTAssertEqual(recorded[2].query["flow"], "verify-seeded")
    }

    func testStartRegistrationFailsWhenSignupDisabled() async {
        let disabled = AuthConfiguration(
            ssoEndpoint: URL(string: "https://sso.test10.meeraspace.com")!,
            ssoXEndpoint: URL(string: "https://sso.test10.meeraspace.com/x")!,
            clientId: .mobileApp,
            scopes: [.openid, .offlineAccess],
            locale: .english,
            loginOptions: [.email],
            signupOptions: [],
            resources: TestAuthResources.sample
        )
        let http = FakeAuthHTTPClient(responses: [])
        let registration = RegistrationFlowService(
            api: SSOAPIClient(http: http, config: disabled),
            config: disabled
        )

        do {
            try await registration.start()
            XCTFail("expected throw")
        } catch let error as AuthError {
            XCTAssertEqual(error.code, .methodDisabled)
            XCTAssertEqual(error.context["fault"], "host.signupOptions")
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    func testBasicRegisterFailsWhenOnlyCivilIdSignupEnabled() async throws {
        let civilOnly = AuthConfiguration(
            ssoEndpoint: URL(string: "https://sso.test10.meeraspace.com")!,
            ssoXEndpoint: URL(string: "https://sso.test10.meeraspace.com/x")!,
            clientId: .mobileApp,
            scopes: [.openid, .offlineAccess],
            locale: .english,
            loginOptions: [.email],
            signupOptions: [.civilId],
            resources: TestAuthResources.sample
        )
        let http = FakeAuthHTTPClient(responses: [
            .ok(FakeSSOJSON.flow(id: "reg-1"))
        ])
        let registration = RegistrationFlowService(
            api: SSOAPIClient(http: http, config: civilOnly),
            config: civilOnly
        )

        try await registration.start()
        do {
            _ = try await registration.submitPassword(
                RegistrationProfile(email: "a@b.com", password: "pw", confirmPassword: "pw")
            )
            XCTFail("expected throw")
        } catch let error as AuthError {
            XCTAssertEqual(error.code, .methodDisabled)
            XCTAssertEqual(error.context["option"], "basic")
        }
    }

    func testCivilIdFailsWhenOnlyBasicSignupEnabled() async throws {
        let basicOnly = AuthConfiguration(
            ssoEndpoint: URL(string: "https://sso.test10.meeraspace.com")!,
            ssoXEndpoint: URL(string: "https://sso.test10.meeraspace.com/x")!,
            clientId: .mobileApp,
            scopes: [.openid, .offlineAccess],
            locale: .english,
            loginOptions: [.email],
            signupOptions: [.basic],
            resources: TestAuthResources.sample
        )
        let http = FakeAuthHTTPClient(responses: [
            .ok(FakeSSOJSON.flow(id: "reg-1"))
        ])
        let registration = RegistrationFlowService(
            api: SSOAPIClient(http: http, config: basicOnly),
            config: basicOnly
        )

        try await registration.start()
        do {
            try await registration.verifyCivilId("1234567", expiry: "2026-01-01")
            XCTFail("expected throw")
        } catch let error as AuthError {
            XCTAssertEqual(error.code, .methodDisabled)
            XCTAssertEqual(error.context["option"], "civilId")
        }
    }
}
