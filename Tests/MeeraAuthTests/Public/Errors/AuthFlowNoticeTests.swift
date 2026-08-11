//
//  AuthFlowNoticeTests.swift
//  MeeraAuthTests
//

import XCTest
@testable import MeeraAuth

final class AuthFlowNoticeTests: XCTestCase {
    private let config = AuthConfiguration(
        ssoEndpoint: URL(string: "https://sso.test10.meeraspace.com")!,
        ssoXEndpoint: URL(string: "https://sso.test10.meeraspace.com/x")!,
        clientId: .mobileApp,
        scopes: [.openid, .offlineAccess],
        locale: .english,
        loginOptions: [.email],
        signupOptions: [.civilId],
        resources: TestAuthResources.sample
    )

    func testParsesInfoMessageIntoCatalogNotice() {
        let messages = [
            FlowMessage(
                text: "mobile has been verified, you can use this mobile to continue registration.",
                type: "info",
                code: 2000,
                context: ["mobile": "+96899998881"]
            )
        ]
        let notices = AuthFlowNotice.notices(from: messages)
        XCTAssertEqual(notices.count, 1)
        XCTAssertEqual(notices[0].code, .success)
        XCTAssertEqual(notices[0].context["mobile"], "+96899998881")
        XCTAssertEqual(notices[0].localizationKey, "auth.info.success")
        XCTAssertFalse(notices[0].localizedDescription.isEmpty)
        XCTAssertNotEqual(
            notices[0].localizedDescription,
            "mobile has been verified, you can use this mobile to continue registration."
        )
    }

    func testCodeSentIsNoticeNotError() {
        let messages = [
            FlowMessage(text: "The code has been send", type: "info", code: 6062, context: nil)
        ]
        let notices = AuthFlowNotice.notices(from: messages)
        XCTAssertEqual(notices.first?.code, .codeHasSend)
        XCTAssertEqual(notices.first?.localizationKey, "auth.info.code_sent")
        XCTAssertNil(ErrorMapper.fromFlowMessages(messages, httpStatus: 400))
    }

    func testInfoTypeNeverMapsToAuthErrorEvenWithHighCode() {
        let messages = [
            FlowMessage(
                text: "Identity already exists",
                type: "info",
                code: 6047,
                context: ["civilID": "9734079"]
            )
        ]
        XCTAssertNil(ErrorMapper.fromFlowMessages(messages, httpStatus: 400))

        let notices = AuthFlowNotice.notices(from: messages)
        XCTAssertEqual(notices.count, 1)
        XCTAssertEqual(notices[0].code, .identityAlreadyExists)
        XCTAssertEqual(notices[0].rawCode, 6047)
        XCTAssertEqual(notices[0].context["civilID"], "9734079")
    }

    func testErrorTypeStillMapsToAuthError() {
        let messages = [
            FlowMessage(
                text: "civilID(9734079) already exists.",
                type: "error",
                code: 6047,
                context: nil
            )
        ]
        let error = ErrorMapper.fromFlowMessages(messages, httpStatus: 400)
        XCTAssertEqual(error?.code, .identityAlreadyExists)
        XCTAssertEqual(error?.rawCode, 6047)
        XCTAssertEqual(error?.message, "civilID(9734079) already exists.")
        XCTAssertTrue(AuthFlowNotice.notices(from: messages).isEmpty)
    }

    func testVerifyMobileOTPReturnsSuccessNotice() async throws {
        let http = FakeAuthHTTPClient(responses: [
            .ok(FakeSSOJSON.flow(id: "reg-1")),
            .ok(FakeSSOJSON.flow(id: "reg-1", flowTokenId: "ft-1")),
            .ok(FakeSSOJSON.flow(id: "reg-1", flowTokenId: "ft-1")),
            .ok(FakeSSOJSON.flow(
                id: "reg-1",
                flowTokenId: "ft-2",
                messages: [[
                    "code": 2000,
                    "type": "info",
                    "text": "mobile has been verified",
                    "context": ["mobile": "+96890000000"]
                ]]
            ))
        ])
        let api = SSOAPIClient(http: http, config: config)
        let registration = RegistrationFlowService(api: api, config: config)

        try await registration.start()
        try await registration.verifyCivilId("1234567", expiry: "2026-01-01")
        _ = try await registration.sendMobileOTP(mobile: "+96890000000", username: "u", useCivilIDMobile: false)
        let notices = try await registration.verifyMobileOTP("1111")

        XCTAssertEqual(notices.count, 1)
        XCTAssertEqual(notices[0].code, .success)
        XCTAssertEqual(notices[0].localizationKey, "auth.info.success")
        XCTAssertEqual(notices[0].context["mobile"], "+96890000000")
    }
}
