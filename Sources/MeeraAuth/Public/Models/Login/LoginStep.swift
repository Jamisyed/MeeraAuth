//
//  LoginStep.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

public enum LoginStep: Sendable, Equatable {
    case requiresMFA(channel: MFAChannel, sessionId: String, notices: [AuthFlowNotice])
    case authenticated(session: Session, notices: [AuthFlowNotice])
}
