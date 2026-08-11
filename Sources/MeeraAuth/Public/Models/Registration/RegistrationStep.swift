//
//  RegistrationStep.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 06/08/2026.
//

import Foundation

public enum RegistrationStep: Sendable, Equatable {
    case requiresVerification
    case completed(Session?)
}
