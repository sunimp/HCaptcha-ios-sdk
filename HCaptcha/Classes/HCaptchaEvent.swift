//
//  HCaptchaEvent.swift
//
//  Created by Sun on 2022/5/10.
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

    // MARK: Nested Types

    public typealias RawValue = String

    // MARK: Computed Properties

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

    // MARK: Lifecycle

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
