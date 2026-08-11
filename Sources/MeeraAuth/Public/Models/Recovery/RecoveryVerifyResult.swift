//
//  RecoveryVerifyResult.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 11/08/2026.
//

import Foundation

public struct RecoveryVerifyResult: Sendable, Equatable {
    public let session: Session
    public let notices: [AuthFlowNotice]

    public init(session: Session, notices: [AuthFlowNotice] = []) {
        self.session = session
        self.notices = notices
    }
}
