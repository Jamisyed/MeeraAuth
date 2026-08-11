//
//  AuthClient+Logout.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 06/08/2026.
//

import Foundation

extension AuthClient {
    // MARK: - Logout

    public func logout() async throws {
        if let token = try await tokenStore.load()?.accessToken {
            _ = try? await api.execute(LogoutRequest.logout(accessToken: token))
        }
        try await sessionStore.clear()
        try await tokenService.clear()
        emit(.loggedOut)
    }
}
