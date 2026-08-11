//
//  FakeAuthHTTPClient.swift
//  MeeraAuthTests
//
//  Created by Syed M Abdul Rehman on 07/08/2026.
//

import Foundation
@testable import MeeraAuth

actor FakeAuthHTTPClient: AuthHTTPClient {
    struct Recorded: Sendable {
        let method: String
        let path: String
        let query: [String: String]
        let headers: [String: String]
        let body: Data?
    }

    private var queue: [AuthHTTPResponse]
    private(set) var recorded: [Recorded] = []

    init(responses: [AuthHTTPResponse] = []) {
        self.queue = responses
    }

    func enqueue(_ response: AuthHTTPResponse) {
        queue.append(response)
    }

    func send(_ request: AuthHTTPRequest) async throws -> AuthHTTPResponse {
        let components = URLComponents(url: request.url, resolvingAgainstBaseURL: false)
        let query = Dictionary(
            uniqueKeysWithValues: (components?.queryItems ?? []).compactMap { item -> (String, String)? in
                guard let value = item.value else { return nil }
                return (item.name, value)
            }
        )
        recorded.append(
            Recorded(
                method: request.method,
                path: request.url.path,
                query: query,
                headers: request.headers,
                body: request.body
            )
        )
        guard !queue.isEmpty else {
            throw AuthError(code: .network, message: "FakeAuthHTTPClient: no queued response for \(request.url)")
        }
        return queue.removeFirst()
    }
}

enum FakeSSOJSON {
    static func flow(
        id: String,
        flowTokenId: String? = nil,
        active: String? = nil,
        username: String? = nil,
        messages: [[String: Any]] = []
    ) -> Data {
        var nodes: [[String: Any]] = []
        if let flowTokenId {
            nodes.append([
                "attributes": [
                    "id": "flowTokenId",
                    "name": "flowTokenId",
                    "value": flowTokenId
                ]
            ])
        }
        if let username {
            nodes.append([
                "attributes": [
                    "id": "username",
                    "name": "username",
                    "value": username
                ]
            ])
        }
        var obj: [String: Any] = [
            "id": id,
            "ui": [
                "forms": [
                    [
                        "nodes": nodes,
                        "messages": messages
                    ]
                ]
            ]
        ]
        if let active { obj["active"] = active }
        return try! JSONSerialization.data(withJSONObject: obj)
    }

    static func session(id: String, withIdentity: Bool) -> Data {
        var obj: [String: Any] = [
            "id": id,
            "authenticatorAssuranceLevel": withIdentity ? "aal2" : "aal1"
        ]
        if withIdentity {
            obj["identity"] = [
                "userId": "user-1",
                "email": "a@b.com"
            ]
        } else {
            obj["identity"] = NSNull()
        }
        return try! JSONSerialization.data(withJSONObject: obj)
    }

    static func tokens(access: String, refresh: String, expiresIn: Int = 3600) -> Data {
        try! JSONSerialization.data(withJSONObject: [
            "access_token": access,
            "refresh_token": refresh,
            "token_type": "bearer",
            "expires_in": expiresIn
        ])
    }

    static func verificationHandoffFlow(id: String, flowTokenId: String = "ft-verify") -> Data {
        try! JSONSerialization.data(withJSONObject: [
            "id": id,
            "type": "api",
            "ui": [
                "forms": [
                    [
                        "id": "captcha",
                        "action": "https://sso.test10.meeraspace.com/x/verification?flow=\(id)",
                        "method": "POST",
                        "nodes": [
                            [
                                "attributes": [
                                    "id": "flowTokenId",
                                    "name": "flowTokenId",
                                    "value": flowTokenId
                                ]
                            ]
                        ],
                        "messages": []
                    ]
                ]
            ]
        ])
    }

    static func identityCompleted(
        userId: String = "user-1",
        email: String = "a@b.com",
        mobile: String = "+96890000000"
    ) -> Data {
        try! JSONSerialization.data(withJSONObject: [
            "subject": "sub",
            "userId": userId,
            "source": "local",
            "username": "user",
            "email": email,
            "emailVerified": true,
            "mobile": mobile,
            "mobileVerified": true,
            "locked": false,
            "firstName": "",
            "middleName": "",
            "lastName": ""
        ])
    }

    static func flowError(id: String, code: Int, text: String) -> Data {
        try! JSONSerialization.data(withJSONObject: [
            "id": id,
            "ui": [
                "forms": [
                    [
                        "nodes": [],
                        "messages": [
                            [
                                "text": text,
                                "type": "error",
                                "code": code
                            ]
                        ]
                    ]
                ]
            ]
        ])
    }
}

extension AuthHTTPResponse {
    static func ok(_ data: Data) -> AuthHTTPResponse {
        AuthHTTPResponse(statusCode: 200, data: data)
    }

    static func badRequest(_ data: Data) -> AuthHTTPResponse {
        AuthHTTPResponse(statusCode: 400, data: data)
    }
}
