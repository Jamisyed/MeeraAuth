//
//  SSOAPIClient.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

actor SSOAPIClient {
    private let http: any AuthHTTPClient
    private let config: AuthConfiguration

    init(http: any AuthHTTPClient, config: AuthConfiguration) {
        self.http = http
        self.config = config
    }

    func execute(_ request: some AuthRequest) async throws -> AuthHTTPResponse {
        let httpRequest = try request.makeHTTPRequest(config: config)
        return try await send(httpRequest)
    }

    private func send(_ request: AuthHTTPRequest) async throws -> AuthHTTPResponse {
        let logging = config.networkLogging
        if logging.isEnabled {
            print(AuthCurlFormatter.requestLog(for: request, mode: logging))
        }

        let clock = ContinuousClock()
        let started = clock.now
        do {
            let response = try await http.send(request)
            let duration = clock.now - started
            if logging.includesResponse {
                print(AuthCurlFormatter.responseLog(response, mode: logging, duration: duration))
            }
            return response
        } catch {
            let duration = clock.now - started
            if logging.includesResponse {
                print(AuthCurlFormatter.errorLog(error, mode: logging, duration: duration))
            }
            if let authError = error as? AuthError {
                throw authError
            }
            throw AuthError.network(error.localizedDescription)
        }
    }
}

extension URL {
    func appending(path: String) -> URL {
        let base = absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: base + "/" + trimmed)!
    }
}
