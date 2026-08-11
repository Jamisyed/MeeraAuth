//
//  AuthErrorPresenter.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 07/08/2026.
//

import Foundation

public enum AuthErrorPresenter {
    public struct Presentation: Equatable, Sendable {
        public let userMessage: String
        public let field: AuthField?
        public let code: AuthErrorCode?
        public let retryable: Bool
        public let serverMessage: String?

        public init(
            userMessage: String,
            field: AuthField?,
            code: AuthErrorCode?,
            retryable: Bool,
            serverMessage: String?
        ) {
            self.userMessage = userMessage
            self.field = field
            self.code = code
            self.retryable = retryable
            self.serverMessage = serverMessage
        }
    }

    public static func present(_ error: Error) -> Presentation {
        guard let authError = error as? AuthError else {
            return Presentation(
                userMessage: AuthErrorCode.unknown.localizedUserMessage,
                field: .general,
                code: nil,
                retryable: false,
                serverMessage: error.localizedDescription
            )
        }

        return Presentation(
            userMessage: authError.userFacingMessage(),
            field: authError.field,
            code: authError.code,
            retryable: authError.retryable,
            serverMessage: authError.message
        )
    }
}
