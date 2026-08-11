//
//  FlowParsingTests.swift
//  MeeraAuthTests
//
//  Created by Syed M Abdul Rehman on 07/08/2026.
//

import XCTest
@testable import MeeraAuth

final class FlowParsingTests: XCTestCase {
    func testParseLoginFlowId() throws {
        let json = """
        {
          "id": "flow1",
          "type": "api",
          "active": "password",
          "ui": {
            "forms": [{
              "id": "password",
              "nodes": [
                { "attributes": { "id": "flowTokenId", "name": "flowTokenId", "value": "tok1" } }
              ],
              "messages": []
            }]
          }
        }
        """.data(using: .utf8)!
        let flow = try FlowJSONParser.parse(json)
        XCTAssertEqual(flow.id, "flow1")
        XCTAssertEqual(flow.flowTokenId, "tok1")
    }

    func testParseSessionWithNullIdentity() throws {
        let json = """
        {
          "id": "sess1",
          "userId": "u1",
          "authenticatorAssuranceLevel": "aal1",
          "identity": null
        }
        """.data(using: .utf8)!
        let session = try FlowJSONParser.parseSession(json)
        XCTAssertEqual(session.id, "sess1")
        XCTAssertTrue(session.requiresMFA)
    }

    func testErrorMapperPassword() {
        let messages = [FlowMessage(text: "bad", type: "error", code: 6051, context: nil)]
        let err = ErrorMapper.fromFlowMessages(messages)
        XCTAssertEqual(err?.code, .passwordMismatch)
        XCTAssertEqual(err?.field, .password)
    }

    func testHostResourceTemplates() {
        let r = TestAuthResources.sample
        XCTAssertEqual(r.mobileOTP, "{sso}{mobileOtpTmpl}")
        XCTAssertEqual(
            r.injecting(locale: .english).mobileOTP,
            "{sso}{en}{mobileOtpTmpl}"
        )
    }

    func testMobileAppScopesAndClientID() {
        XCTAssertEqual(
            [AuthScope].mobileApp.asSpaceSeparatedString,
            "openid email mobile groups profile offline_access"
        )
        XCTAssertEqual(AuthClientID.mobileApp.rawValue, "mobile-app")
        XCTAssertEqual(AuthLocale.english.rawValue, "en")
        XCTAssertEqual(AuthLocale.arabic.rawValue, "ar")
    }

    func testCustomScopeAndClientID() {
        XCTAssertEqual(AuthScope.custom("roles").rawValue, "roles")
        XCTAssertEqual(
            ([AuthScope.openid, .custom("roles"), .offlineAccess] as [AuthScope])
                .asSpaceSeparatedString,
            "openid roles offline_access"
        )
        XCTAssertEqual(AuthClientID.custom("partner-app").rawValue, "partner-app")
        XCTAssertEqual(
            ([AuthScope.openid, .custom("  "), .email] as [AuthScope])
                .asSpaceSeparatedString,
            "openid email"
        )
    }
}