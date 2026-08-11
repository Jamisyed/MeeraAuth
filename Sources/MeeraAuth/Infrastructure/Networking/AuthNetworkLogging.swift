//
//  AuthNetworkLogging.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

public enum AuthNetworkLogging: Sendable, Equatable {
    case off
    case log
    case verbose
    case curl

    public var isEnabled: Bool {
        self != .off
    }

    public var includesResponse: Bool {
        switch self {
        case .log, .verbose: return true
        case .off, .curl: return false
        }
    }

    public var redactSensitiveValues: Bool {
        self == .log
    }

    public var includesErrorCode: Bool {
        self != .off
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var _current: AuthNetworkLogging = .off

    public static var current: AuthNetworkLogging {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _current
        }
        set {
            lock.lock()
            _current = newValue
            lock.unlock()
        }
    }
}
