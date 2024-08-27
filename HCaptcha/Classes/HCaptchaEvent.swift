//
//  HCaptchaEvent.swift
//  HCaptcha
//
//  Copyright © 2022 HCaptcha. All rights reserved.
//

import Foundation

/// Events which can be received from HCaptcha SDK
@objc
public enum HCaptchaEvent: Int, RawRepresentable {
    case open
    case expired
    case challengeExpired
    case close
    case error

    public typealias RawValue = String

    public var rawValue: RawValue {
        switch self {
        case .open:
            "open"
        case .expired:
            "expired"
        case .challengeExpired:
            "challengeExpired"
        case .close:
            "close"
        case .error:
            "error"
        }
    }

    public init?(rawValue: RawValue) {
        switch rawValue {
        case "open":
            self = .open
        case "expired":
            self = .expired
        case "challengeExpired":
            self = .challengeExpired
        case "close":
            self = .close
        case "error":
            self = .error
        default:
            return nil
        }
    }
}
