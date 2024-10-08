//
//  HCaptchaResult.swift
//
//  Created by Sun on 2020/6/25.
//

import Foundation

/// The HCaptcha result.
///
/// This may contain the validation token on success, or an error that may have occurred.
@objc
public class HCaptchaResult: NSObject {
    // MARK: Properties

    /// Result token
    let token: String?

    /// Result error
    let error: HCaptchaError?

    /// Manager
    let manager: HCaptchaWebViewManager

    // MARK: Lifecycle

    init(_ manager: HCaptchaWebViewManager, token: String? = nil, error: HCaptchaError? = nil) {
        self.manager = manager
        self.token = token
        self.error = error
    }

    // MARK: Functions

    /// - returns: The validation token uppon success.
    ///
    /// Tries to unwrap the Result and retrieve the token if it's successful.
    ///
    /// - Throws: `HCaptchaError`
    @objc
    public func dematerialize() throws -> String {
        manager.resultHandled = true

        if let token {
            return token
        }

        if let error {
            throw error
        }

        assertionFailure("Impossible state result must be initialized with token or error")
        return ""
    }
}
