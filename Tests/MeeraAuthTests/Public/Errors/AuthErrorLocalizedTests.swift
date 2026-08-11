//
//  AuthErrorLocalizedTests.swift
//  MeeraAuthTests
//
//  Created by Syed M Abdul Rehman on 07/08/2026.
//

import XCTest
@testable import MeeraAuth

final class AuthErrorLocalizedTests: XCTestCase {
    override func setUp() {
        super.setUp()
        AuthLocalization.locale = .english
        AuthNetworkLogging.current = .off
    }

    override func tearDown() {
        AuthLocalization.locale = .english
        AuthNetworkLogging.current = .off
        super.tearDown()
    }

    func testLocalizedDescriptionUsesCatalogNotServerMessage() {
        let error = AuthError(
            code: .identityAlreadyExists,
            message: "civilID(9734079) already exists."
        )
        XCTAssertEqual(error.message, "civilID(9734079) already exists.")
        XCTAssertNotEqual(error.localizedDescription, error.message)
        XCTAssertFalse(error.localizedDescription.isEmpty)
        assertUserFacing(error, catalog: AuthErrorCode.identityAlreadyExists.localizedUserMessage)
    }

    func testNetworkFactoryMaps403ToForbiddenCatalogMessage() {
        let error = AuthError.network("Access is Denied", status: 403)
        XCTAssertEqual(error.code, .forbidden)
        XCTAssertEqual(error.httpStatus, 403)
        XCTAssertEqual(error.message, "Access is Denied")
        assertUserFacing(error, catalog: AuthErrorCode.forbidden.localizedUserMessage)
        XCTAssertNotEqual(error.userFacingMessage(), AuthErrorCode.network.localizedUserMessage)
    }

    func testNetworkFactoryMaps401ToUnauthorized() {
        let error = AuthError.network("Unauthorized", status: 401)
        XCTAssertEqual(error.code, .unauthorized)
        XCTAssertEqual(error.httpStatus, 401)
    }

    func testNetworkFactoryMaps503ToServiceUnavailable() {
        let error = AuthError.network("Service Unavailable", status: 503)
        XCTAssertEqual(error.code, .serviceUnavailable)
        XCTAssertEqual(error.httpStatus, 503)
        XCTAssertTrue(error.retryable)
        assertUserFacing(error, catalog: AuthErrorCode.serviceUnavailable.localizedUserMessage)
        XCTAssertNotEqual(error.userFacingMessage(), AuthErrorCode.network.localizedUserMessage)
    }

    func testNetworkFactoryMapsCommonHTTPStatuses() {
        XCTAssertEqual(AuthError.network("x", status: 400).code, .unknown)
        XCTAssertEqual(AuthError.network("x", status: 404).code, .notFound)
        XCTAssertEqual(AuthError.network("x", status: 408).code, .serviceUnavailable)
        XCTAssertEqual(AuthError.network("x", status: 422).code, .invalidArguments)
        XCTAssertEqual(AuthError.network("x", status: 429).code, .accessLimitFrequently)
        XCTAssertEqual(AuthError.network("x", status: 502).code, .serviceUnavailable)
        XCTAssertEqual(AuthError.network("x", status: nil).code, .network)

        assertUserFacing(AuthError.network("x", status: 404), catalog: AuthErrorCode.notFound.localizedUserMessage)
        assertUserFacing(AuthError.network("x", status: 400), catalog: AuthErrorCode.unknown.localizedUserMessage)
        assertUserFacing(
            AuthError.network("x", status: 429),
            catalog: AuthErrorCode.accessLimitFrequently.localizedUserMessage
        )
    }

    func testFlowMessage6084MapsToIdentityNotSync() {
        let error = ErrorMapper.fromFlowMessages(
            [FlowMessage(text: "Failed to register in Tawteen, please try again.", type: "error", code: 6084, context: nil)],
            httpStatus: 400
        )
        XCTAssertEqual(error?.code, .identityNotSync)
        XCTAssertEqual(error?.rawCode, 6084)
        XCTAssertEqual(error?.httpStatus, 400)
        XCTAssertEqual(error?.message, "Failed to register in Tawteen, please try again.")
        XCTAssertNotNil(error)
        if let error {
            assertUserFacing(error, catalog: AuthErrorCode.identityNotSync.localizedUserMessage, code: 6084)
        }
    }

    func testHTTP400InvalidArgumentsMapsToCatalog() {
        let error = ErrorMapper.fromFlowMessages(
            [FlowMessage(text: "the username is empty, it is required", type: "error", code: 4001, context: nil)],
            httpStatus: 400
        )
        XCTAssertEqual(error?.code, .invalidArguments)
        XCTAssertEqual(error?.message, "the username is empty, it is required")
        XCTAssertNotNil(error)
        if let error {
            assertUserFacing(error, catalog: AuthErrorCode.invalidArguments.localizedUserMessage, code: 4001)
        }
    }

    func testNoStrategyResponsibleShowsGenericCatalogWithCodeWhenLoggingOn() {
        AuthNetworkLogging.current = .log
        let error = ErrorMapper.fromFlowMessages(
            [FlowMessage(text: "could not find a strategy to sign up with", type: "error", code: 6006, context: nil)],
            httpStatus: 400
        )
        XCTAssertEqual(error?.code, .noStrategyResponsible)
        XCTAssertEqual(error?.rawCode, 6006)
        XCTAssertNotNil(error)
        if let error {
            assertUserFacing(error, catalog: AuthErrorCode.unknown.localizedUserMessage, code: 6006)
            XCTAssertEqual(
                AuthErrorCode.noStrategyResponsible.localizationKey,
                "auth.error.generic"
            )
        }
    }

    func testUserFacingMessageOmitsCodeWhenNetworkLoggingOff() {
        AuthNetworkLogging.current = .off
        let error = AuthError(code: .noStrategyResponsible, message: "x", rawCode: 6006)
        XCTAssertEqual(
            error.userFacingMessage(),
            AuthErrorCode.noStrategyResponsible.localizedUserMessage
        )
        XCTAssertFalse(error.userFacingMessage().contains("(6006)"))
    }

    func testUserFacingMessageIncludesCodeWhenNetworkLoggingOn() {
        AuthNetworkLogging.current = .verbose
        let error = AuthError(code: .noStrategyResponsible, message: "x", rawCode: 6006)
        XCTAssertEqual(
            error.userFacingMessage(),
            "\(AuthErrorCode.noStrategyResponsible.localizedUserMessage) (6006)"
        )
    }

    func testFlowExpiredIsRetryableAndLocalized() {
        let error = AuthError(code: .flowExpired, message: "Flow Expired")
        XCTAssertTrue(error.retryable)
        XCTAssertEqual(error.code, .flowExpired)
        assertUserFacing(error, catalog: AuthErrorCode.flowExpired.localizedUserMessage)
    }

    func testIdentityAlreadyExistsFieldFromCivilIdMessage() {
        let field = ErrorMapper.field(
            for: .identityAlreadyExists,
            message: "civilID(9734079) already exists."
        )
        XCTAssertEqual(field, .civilId)
    }

    func testAuthLocaleArabicOverridesDeviceLanguageForErrors() {
        AuthLocalization.locale = .arabic
        AuthNetworkLogging.current = .off
        let error = AuthError(
            code: .identityAlreadyExists,
            message: "civilID(9734079) already exists."
        )
        let arabic = error.userFacingMessage()
        let english = error.userFacingMessage(locale: .english)
        XCTAssertNotEqual(arabic, english)
        XCTAssertEqual(arabic, AuthErrorCode.identityAlreadyExists.localizedUserMessage(locale: .arabic))
        XCTAssertFalse(arabic.contains("already registered"))
    }

    func testAuthClientInitSetsAuthLocalizationLocaleAndNetworkLogging() {
        AuthLocalization.locale = .english
        AuthNetworkLogging.current = .off
        let config = AuthConfiguration(
            ssoEndpoint: URL(string: "https://sso.test10.meeraspace.com")!,
            ssoXEndpoint: URL(string: "https://sso.test10.meeraspace.com/x")!,
            clientId: .mobileApp,
            scopes: [.openid, .offlineAccess],
            locale: .arabic,
            loginOptions: [.email],
            resources: TestAuthResources.sample,
            networkLogging: .curl
        )
        _ = AuthClient(
            configuration: config,
            httpClient: FakeAuthHTTPClient(responses: []),
            sessionStore: InMemorySessionStore(),
            tokenStore: InMemoryTokenStore()
        )
        XCTAssertEqual(AuthLocalization.locale, .arabic)
        XCTAssertEqual(AuthNetworkLogging.current, .curl)
    }

    private func assertUserFacing(
        _ error: AuthError,
        catalog: String,
        code: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectedCode = code ?? error.rawCode ?? error.code.rawValue
        let actual = error.userFacingMessage()
        if AuthNetworkLogging.current != .off {
            XCTAssertEqual(actual, "\(catalog) (\(expectedCode))", file: file, line: line)
        } else {
            XCTAssertEqual(actual, catalog, file: file, line: line)
        }
        XCTAssertEqual(error.localizedDescription, actual, file: file, line: line)
    }
}
