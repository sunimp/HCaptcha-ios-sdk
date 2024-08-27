//
//  HCaptchaError.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 22/03/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

import Foundation

/// The codes of possible errors thrown by HCaptcha
public enum HCaptchaError: Error, CustomStringConvertible {

    /// Unexpected error
    case unexpected(Error)

    /// Internet connection is missing
    case networkError

    /// Could not load the HTML embedded in the bundle
    case htmlLoadError

    /// HCaptchaKey was not provided
    case apiKeyNotFound

    /// HCaptchaDomain was not provided
    case baseURLNotFound

    /// Received an unexpected message from javascript
    case wrongMessageFormat

    /// HCaptcha setup failed
    case failedSetup

    /// HCaptcha response or session expired
    case sessionTimeout

    /// user closed HCaptcha without answering
    case challengeClosed

    /// HCaptcha server rate-limited user request
    case rateLimit

    /// Invalid custom theme passed
    case invalidCustomTheme

    public static func == (lhs: HCaptchaError, rhs: HCaptchaError) -> Bool {
        lhs.description == rhs.description
    }

    /// A human-readable description for each error
    public var description: String {
        switch self {
        case .unexpected(let error):
            "Unexpected Error: \(error)"

        case .networkError:
            "Network issues"

        case .htmlLoadError:
            "Could not load embedded HTML"

        case .apiKeyNotFound:
            "HCaptchaKey not provided"

        case .baseURLNotFound:
            "HCaptchaDomain not provided"

        case .wrongMessageFormat:
            "Unexpected message from javascript"

        case .failedSetup:
            """
            ⚠️ WARNING! HCaptcha wasn't successfully configured. Please double check your HCaptchaKey and HCaptchaDomain.
            Also check that you're using the hCaptcha **SITE KEY** for client side integration.
            """

        case .sessionTimeout:
            "Response expired and need to re-verify"

        case .challengeClosed:
            "User closed challenge without answering"

        case .rateLimit:
            "User was rate-limited"

        case .invalidCustomTheme:
            "Invalid JSON or JSObject as customTheme"
        }
    }
}
