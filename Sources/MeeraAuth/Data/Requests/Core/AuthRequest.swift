//
//  AuthRequest.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 06/08/2026.
//

import Foundation

protocol AuthRequest: Sendable {
    var base: AuthAPIBase { get }
    var path: String { get }
    var method: AuthRequestMethod { get }
    var headers: [String: String] { get }
    var query: [String: String] { get }
    var body: AuthJSONObject? { get }
    var bodyEncoding: AuthBodyEncoding { get }
    var sessionId: String? { get }
    var bearerToken: String? { get }
}

extension AuthRequest {
    var base: AuthAPIBase { .ssoX }
    var headers: [String: String] { [:] }
    var query: [String: String] { [:] }
    var body: AuthJSONObject? { nil }
    var bodyEncoding: AuthBodyEncoding { .json }
    var sessionId: String? { nil }
    var bearerToken: String? { nil }

    func makeHTTPRequest(config: AuthConfiguration) throws -> AuthHTTPRequest {
        var components = URLComponents(
            url: base.url(from: config).appending(path: path),
            resolvingAgainstBaseURL: false
        )!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else {
            throw AuthError(code: .invalidArguments, message: "Invalid URL for \(path)")
        }

        var headers = self.headers
        var bodyData: Data?

        if let body {
            switch bodyEncoding {
            case .json:
                if headers["Content-Type"] == nil {
                    headers["Content-Type"] = "application/json"
                }
                if headers["Accept"] == nil {
                    headers["Accept"] = "application/json"
                }
                bodyData = try body.encodedJSON()
            case .formURLEncoded:
                if headers["Content-Type"] == nil {
                    headers["Content-Type"] = "application/x-www-form-urlencoded"
                }
                if headers["Accept"] == nil {
                    headers["Accept"] = "application/json"
                }
                bodyData = body.encodedFormURL()
            }
        } else if method == .get || method == .delete {
            if headers["Accept"] == nil {
                headers["Accept"] = "application/json"
            }
        }

        if let sessionId {
            headers["X-SESSION-ID"] = sessionId
        }
        if let bearerToken {
            headers["Authorization"] = "Bearer \(bearerToken)"
        }

        return AuthHTTPRequest(
            method: method.rawValue,
            url: url,
            headers: headers,
            body: bodyData
        )
    }
}

extension String {
    var urlQueryEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?
            .replacingOccurrences(of: "+", with: "%2B") ?? self
    }
}
