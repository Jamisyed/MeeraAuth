//
//  CivilIdVerificationResult.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 10/08/2026.
//

import Foundation

public struct CivilIdVerificationResult: Sendable, Equatable {
    public let username: String?
    public let notices: [AuthFlowNotice]

    public init(username: String?, notices: [AuthFlowNotice] = []) {
        self.username = username
        self.notices = notices
    }
}
