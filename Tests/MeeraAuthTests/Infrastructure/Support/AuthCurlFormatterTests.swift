//
//  AuthCurlFormatterTests.swift
//  MeeraAuthTests
//
//  Created by Syed M Abdul Rehman on 07/08/2026.
//

import XCTest
@testable import MeeraAuth

final class AuthCurlFormatterTests: XCTestCase {
    func testLogModeRedactsSecrets() {
        let body = #"{"email":"a@b.com","password":"secret","method":"password"}"#.data(using: .utf8)!
        let request = AuthHTTPRequest(
            method: "POST",
            url: URL(string: "https://sso.example.com/x/login?flow=abc")!,
            headers: [
                "Content-Type": "application/json",
                "Accept": "application/json",
                "Authorization": "Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.payload.sig"
            ],
            body: body
        )

        let curl = AuthCurlFormatter.requestLog(for: request, mode: .log)

        XCTAssertTrue(curl.contains("MeeraAuth · START · log"))
        XCTAssertTrue(curl.contains("→ REQUEST"))
        XCTAssertTrue(curl.contains("POST https://sso.example.com/x/login?flow=abc"))
        XCTAssertTrue(curl.contains("$ curl -v \\"))
        XCTAssertTrue(curl.contains("-X POST \\"))
        XCTAssertTrue(curl.contains("-H \"Content-Type: application/json\" \\"))
        XCTAssertTrue(curl.contains("\"https://sso.example.com/x/login?flow=abc\""))
        XCTAssertTrue(curl.contains("[redacted]"))
        XCTAssertFalse(curl.contains("secret"))
        XCTAssertFalse(curl.contains("eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.payload.sig"))
    }

    func testVerboseKeepsSecrets() {
        let body = #"{"password":"secret"}"#.data(using: .utf8)!
        let request = AuthHTTPRequest(
            method: "POST",
            url: URL(string: "https://sso.example.com/x/login")!,
            headers: ["Authorization": "Bearer tokensecret"],
            body: body
        )
        let curl = AuthCurlFormatter.requestLog(for: request, mode: .verbose)
        XCTAssertTrue(curl.contains("MeeraAuth · START · verbose"))
        XCTAssertTrue(curl.contains("secret"))
        XCTAssertTrue(curl.contains("Bearer tokensecret"))
    }

    func testResponseLogIsStructuredAndPrettyPrinted() {
        let data = #"{"access_token":"tok","expires_in":3600}"#.data(using: .utf8)!
        let response = AuthHTTPResponse(statusCode: 200, data: data)
        let log = AuthCurlFormatter.responseLog(
            response,
            mode: .log,
            duration: .milliseconds(42)
        )

        XCTAssertTrue(log.contains("← RESPONSE  HTTP 200 · 42ms ·"))
        XCTAssertTrue(log.contains("MeeraAuth · END"))
        XCTAssertTrue(log.contains("[redacted]"))
        XCTAssertFalse(log.contains("\"tok\""))
        XCTAssertTrue(log.contains("expires_in"))
    }

    func testErrorLogIncludesAuthErrorFields() {
        let error = AuthError(
            code: .unauthorized,
            message: "denied",
            httpStatus: 401
        )
        let log = AuthCurlFormatter.errorLog(error, mode: .verbose, duration: .milliseconds(8))
        XCTAssertTrue(log.contains("← RESPONSE  ERROR · 8ms"))
        XCTAssertTrue(log.contains("MeeraAuth · END"))
        XCTAssertTrue(log.contains("code: \(AuthErrorCode.unauthorized.rawValue)"))
        XCTAssertTrue(log.contains("message: denied"))
        XCTAssertTrue(log.contains("httpStatus: 401"))
    }

    func testCurlModePrintsFramedCommandWithoutResponse() {
        let body = #"{"password":"secret"}"#.data(using: .utf8)!
        let request = AuthHTTPRequest(
            method: "POST",
            url: URL(string: "https://sso.example.com/x/token/exchange")!,
            headers: [
                "Content-Type": "application/x-www-form-urlencoded",
                "X-SESSION-ID": "session-secret-value"
            ],
            body: body
        )

        let curl = AuthCurlFormatter.requestLog(for: request, mode: .curl)
        XCTAssertTrue(curl.contains("MeeraAuth · START · curl"))
        XCTAssertTrue(curl.contains("→ REQUEST"))
        XCTAssertTrue(curl.contains("POST https://sso.example.com/x/token/exchange"))
        XCTAssertTrue(curl.contains("$ curl -v \\"))
        XCTAssertTrue(curl.contains("session-secret-value"))
        XCTAssertTrue(curl.contains("secret"))
        XCTAssertTrue(curl.contains("MeeraAuth · END"))
        XCTAssertFalse(curl.contains("← RESPONSE"))

        let response = AuthCurlFormatter.responseLog(
            AuthHTTPResponse(statusCode: 200, data: Data("{}".utf8)),
            mode: .curl
        )
        XCTAssertTrue(response.isEmpty)
    }
}
