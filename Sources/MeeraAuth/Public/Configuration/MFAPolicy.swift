//
//  MFAPolicy.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

public struct MFAPolicy: Sendable, Equatable {
    public var autoSendOTP: Bool

    public init(autoSendOTP: Bool = true) {
        self.autoSendOTP = autoSendOTP
    }
}
