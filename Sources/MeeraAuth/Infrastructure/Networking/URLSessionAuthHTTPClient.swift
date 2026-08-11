//
//  URLSessionAuthHTTPClient.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

public struct URLSessionAuthHTTPClient: AuthHTTPClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send(_ request: AuthHTTPRequest) async throws -> AuthHTTPResponse {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method
        urlRequest.httpBody = request.body
        for (k, v) in request.headers {
            urlRequest.setValue(v, forHTTPHeaderField: k)
        }
        let (data, response) = try await session.data(for: urlRequest)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        var headers: [String: String] = [:]
        if let http = response as? HTTPURLResponse {
            for (k, v) in http.allHeaderFields {
                if let key = k as? String, let value = v as? String {
                    headers[key] = value
                }
            }
        }
        return AuthHTTPResponse(statusCode: status, data: data, headers: headers)
    }
}
