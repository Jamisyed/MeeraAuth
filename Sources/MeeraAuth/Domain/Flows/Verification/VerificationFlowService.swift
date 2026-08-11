//
//  VerificationFlowService.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

protocol VerificationFlowServing: Sendable {
    func start() async throws
    func seed(flowId: String, flowTokenId: String?) async
    @discardableResult
    func sendOTP(via channel: MFAChannel, identifier: String) async throws -> [AuthFlowNotice]
    @discardableResult
    func resendOTP() async throws -> [AuthFlowNotice]
    @discardableResult
    func verifyOTP(_ code: String) async throws -> [AuthFlowNotice]
}

actor VerificationFlowService: VerificationFlowServing {
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
        let response = try await api.execute(VerificationRequest.start)
        let flow = try FlowJSONParser.parse(response.data)
        flowId = flow.id
        flowTokenId = nil
    }

    func seed(flowId: String, flowTokenId: String?) async {
        self.flowId = flowId
        self.flowTokenId = flowTokenId
        lastSendBody = [:]
    }

    @discardableResult
    func sendOTP(via channel: MFAChannel, identifier: String) async throws -> [AuthFlowNotice] {
        guard let flowId else { throw AuthError(code: .invalidState, message: "Call start() first") }
        let resources = config.resolvedResources
        let resource = channel == .email ? resources.activeEmail : resources.activeMobile
        let request = VerificationRequest.sendOTP(
            flowId: flowId,
            channel: channel,
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
    func resendOTP() async throws -> [AuthFlowNotice] {
        guard let flowId else { throw AuthError(code: .invalidState, message: "Call start() first") }
        var body = lastSendBody
        if let flowTokenId { body["flowTokenId"] = .string(flowTokenId) }
        let response = try await api.execute(
            VerificationRequest.resendOTP(flowId: flowId, body: body)
        )
        let flow = try parse(response)
        self.flowId = flow.id
        self.flowTokenId = flow.flowTokenId
        return AuthFlowNotice.notices(from: flow.messages)
    }

    @discardableResult
    func verifyOTP(_ code: String) async throws -> [AuthFlowNotice] {
        guard let flowId, let flowTokenId else {
            throw AuthError(code: .invalidState, message: "Send OTP first")
        }
        var body = lastSendBody
        body["code"] = .string(code)
        body["flowTokenId"] = .string(flowTokenId)
        body["method"] = .string("captcha")
        body.removeValue(forKey: "email")
        body.removeValue(forKey: "mobile")
        let response = try await api.execute(
            VerificationRequest.verifyOTP(flowId: flowId, body: body)
        )
        let flow = try parse(response)
        if flow.state != "passed_challenge",
           !flow.messages.contains(where: { $0.code == AuthErrorCode.codeCompleted.rawValue }) {
            if let err = ErrorMapper.fromFlowMessages(flow.messages, httpStatus: response.statusCode) {
                throw err
            }
        }
        return AuthFlowNotice.notices(from: flow.messages)
    }

    private func parse(_ response: AuthHTTPResponse) throws -> ParsedFlow {
        let flow = try FlowJSONParser.parse(response.data)
        if let err = ErrorMapper.fromFlowMessages(flow.messages, httpStatus: response.statusCode) {
            throw err
        }
        return flow
    }
}
