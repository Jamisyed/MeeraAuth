//
//  AuthHTTPClient.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

public struct AuthHTTPRequest: Sendable {
    public var method: String
    public var url: URL
    public var headers: [String: String]
    public var body: Data?

    public init(method: String, url: URL, headers: [String: String] = [:], body: Data? = nil) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
    }
}

public struct AuthHTTPResponse: Sendable {
    public var statusCode: Int
    public var data: Data
    public var headers: [String: String]

    public init(statusCode: Int, data: Data, headers: [String: String] = [:]) {
        self.statusCode = statusCode
        self.data = data
        self.headers = headers
    }
}

public protocol AuthHTTPClient: Sendable {
    func send(_ request: AuthHTTPRequest) async throws -> AuthHTTPResponse
}
