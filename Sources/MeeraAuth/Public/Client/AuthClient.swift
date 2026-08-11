//
//  AuthClient.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

/// Thread-safe facade for host applications.
public actor AuthClient: AuthClientServing {
    public nonisolated let configuration: AuthConfiguration

    let sessionStore: any SessionStore
    let tokenStore: any TokenStore
    let api: SSOAPIClient
    let loginFlow: any LoginFlowServing
    let registrationFlow: any RegistrationFlowServing
    let recoveryFlow: any RecoveryFlowServing
    let verificationFlow: any VerificationFlowServing
    let settingsFlow: any SettingsFlowServing
    let tokenService: any TokenServing

    var eventContinuations: [UUID: AsyncStream<AuthEvent>.Continuation] = [:]

    public init(
        configuration: AuthConfiguration,
        httpClient: any AuthHTTPClient,
        sessionStore: any SessionStore = InMemorySessionStore(),
        tokenStore: any TokenStore = KeychainTokenStore()
    ) {
        AuthConfiguration.assertValid(configuration)
        AuthLocalization.locale = configuration.locale
        AuthNetworkLogging.current = configuration.networkLogging
        self.configuration = configuration
        self.sessionStore = sessionStore
        self.tokenStore = tokenStore
        let api = SSOAPIClient(http: httpClient, config: configuration)
        self.api = api
        self.loginFlow = LoginFlowService(api: api, config: configuration)
        self.registrationFlow = RegistrationFlowService(api: api, config: configuration)
        self.recoveryFlow = RecoveryFlowService(api: api, config: configuration)
        self.verificationFlow = VerificationFlowService(api: api, config: configuration)
        self.settingsFlow = SettingsFlowService(api: api, config: configuration)
        self.tokenService = TokenService(api: api, config: configuration, tokenStore: tokenStore)
    }
}
