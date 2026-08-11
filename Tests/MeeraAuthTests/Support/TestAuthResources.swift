//
//  TestAuthResources.swift
//  MeeraAuthTests
//
//  Created by Syed M Abdul Rehman on 07/08/2026.
//

import MeeraAuth

enum TestAuthResources {
    static let sample = AuthResourceTemplates(
        emailOTP: "{sso}{emailOtpTmpl}",
        mobileOTP: "{sso}{mobileOtpTmpl}",
        resetEmail: "{sso}{resetEmailTmpl}",
        resetMobile: "{sso}{resetMobileTmpl}",
        activeEmail: "{sso}{activeEmailTmpl}",
        activeMobile: "{sso}{activeMobileTmpl}"
    )
}
