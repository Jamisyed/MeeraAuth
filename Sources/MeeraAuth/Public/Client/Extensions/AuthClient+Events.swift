//
//  AuthClient+Events.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 06/08/2026.
//

import Foundation

extension AuthClient {
    // MARK: - Events

    public func events() -> AsyncStream<AuthEvent> {
        let id = UUID()
        return AsyncStream { continuation in
            eventContinuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeContinuation(id) }
            }
        }
    }

    func removeContinuation(_ id: UUID) {
        eventContinuations[id] = nil
    }

    func emit(_ event: AuthEvent) {
        for continuation in eventContinuations.values {
            continuation.yield(event)
        }
    }
}
