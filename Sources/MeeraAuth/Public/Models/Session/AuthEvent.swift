//
//  AuthEvent.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

public enum AuthEvent: Sendable, Equatable {
    case loggedIn(Session)
    case loggedOut
    case tokensUpdated(TokenSet)
    case sessionUpdated(Session)
}
