//
//  RecoveryFlowService.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

protocol RecoveryFlowServing: Sendable {
    func start() async throws
    @discardableResult
    func sendCode(option: LoginOption, identifier: String) async throws -> [AuthFlowNotice]
    @discardableResult
    func resendCode() async throws -> [AuthFlowNotice]
    @discardableResult
    func verifyCode(_ code: String) async throws -> RecoveryVerifyResult
}

actor RecoveryFlowService: RecoveryFlowServing {
    private let api: SSOAPIClient
    private let config: AuthConfiguration
    private var flowId: String?
    private var flowTokenId: String?
    private var lastSendBody: AuthJSONObject = [:]

    init(api: SSOAPIClient, config: AuthConfiguration) {
        self.api = api
        self.config = config
    }

    func start() async throws {
        let response = try await api.execute(RecoveryRequest.start)
        let flow = try FlowJSONParser.parse(response.data)
        flowId = flow.id
        flowTokenId = nil
        lastSendBody = [:]
    }

    @discardableResult
    func sendCode(option: LoginOption, identifier: String) async throws -> [AuthFlowNotice] {
        guard let flowId else { throw AuthError(code: .invalidState, message: "Call start() first") }
        let resources = config.resolvedResources
        let resource: String
        switch option {
        case .email: resource = resources.resetEmail
        case .phone, .civilId: resource = resources.resetMobile
        }
        let request = RecoveryRequest.sendCode(
            flowId: flowId,
            option: option,
            identifier: identifier,
            resource: resource
        )
        lastSendBody = request.body ?? [:]
        let response = try await api.execute(request)
        let flow = try parse(response)
        self.flowId = flow.id
        self.flowTokenId = flow.flowTokenId
        return AuthFlowNotice.notices(from: flow.messages)
    }

    @discardableResult
    func resendCode() async throws -> [AuthFlowNotice] {
        guard let flowId else { throw AuthError(code: .invalidState, message: "Call start() first") }
        var body = lastSendBody
        body["method"] = .string("captcha")
        if let flowTokenId { body["flowTokenId"] = .string(flowTokenId) }
        let response = try await api.execute(
            RecoveryRequest.resendCode(flowId: flowId, body: body)
        )
        let flow = try parse(response)
        self.flowId = flow.id
        self.flowTokenId = flow.flowTokenId
        return AuthFlowNotice.notices(from: flow.messages)
    }

    @discardableResult
    func verifyCode(_ code: String) async throws -> RecoveryVerifyResult {
        guard let flowId, let flowTokenId else {
            throw AuthError(code: .invalidState, message: "Send code first")
        }
        let response = try await api.execute(
            RecoveryRequest.verifyCode(flowId: flowId, flowTokenId: flowTokenId, code: code)
        )
        var notices: [AuthFlowNotice] = []
        if let flow = try? FlowJSONParser.parse(response.data) {
            if let err = ErrorMapper.fromFlowMessages(flow.messages, httpStatus: response.statusCode) {
                throw err
            }
            notices = AuthFlowNotice.notices(from: flow.messages)
        }
        let session = try FlowJSONParser.parseSession(response.data)
        return RecoveryVerifyResult(session: session, notices: notices)
    }

    private func parse(_ response: AuthHTTPResponse) throws -> ParsedFlow {
        let flow = try FlowJSONParser.parse(response.data)
        if let err = ErrorMapper.fromFlowMessages(flow.messages, httpStatus: response.statusCode) {
            throw err
        }
        return flow
    }
}
