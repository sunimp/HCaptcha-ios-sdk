//
//  HCaptchaDecoder.swift
//
//  Created by Sun on 2020/6/25.
//

import Foundation
import WebKit

// MARK: - HCaptchaDecoder

/// The Decoder of javascript messages from the webview
class HCaptchaDecoder: NSObject {
    // MARK: Nested Types

    /// The decoder result.
    enum Result {
        /// A result token, if any
        case token(String)

        /// Indicates that the webview containing the challenge should be displayed.
        case showHCaptcha

        /// Any errors
        case error(HCaptchaError)

        /// Did finish loading resources
        case didLoad

        /// Did a challenge become visible
        case onOpen

        /// Called when the user display of a challenge times out with no answer.
        case onChallengeExpired

        /// Called when the passcode response expires and the user must re-verify.
        case onExpired

        /// Called when the user dismisses a challenge.
        case onClose

        /// Logs a string onto the console
        case log(String)
    }

    // MARK: Properties

    /// The closure that receives messages
    fileprivate let sendMessage: (Result) -> Void

    // MARK: Lifecycle

    /// - parameter didReceiveMessage: A closure that receives a HCaptchaDecoder.Result
    ///
    /// Initializes a decoder with a completion closure.
    init(didReceiveMessage: @escaping (Result) -> Void) {
        sendMessage = didReceiveMessage

        super.init()
    }

    // MARK: Functions

    /// - parameter error: The error to be sent.
    ///
    /// Sends an error to the completion closure
    func send(error: HCaptchaError) {
        sendMessage(.error(error))
    }
}

// MARK: WKScriptMessageHandler

/// Makes HCaptchaDecoder conform to `WKScriptMessageHandler`
extension HCaptchaDecoder: WKScriptMessageHandler {
    func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String: Any] else {
            return sendMessage(.error(.wrongMessageFormat))
        }

        sendMessage(Result.from(response: dict))
    }
}

// MARK: - Result

/// Private methods on `HCaptchaDecoder.Result`
extension HCaptchaDecoder.Result {
    /// - parameter response: A dictionary containing the message to be parsed
    /// - returns: A decoded HCaptchaDecoder.Result
    ///
    /// Parses a dict received from the webview onto a `HCaptchaDecoder.Result`
    fileprivate static func from(response: [String: Any]) -> HCaptchaDecoder.Result {
        if let token = response["token"] as? String {
            return .token(token)
        } else if let message = response["log"] as? String {
            return .log(message)
        } else if let error = response["error"] as? Int {
            return from(error)
        }

        if let action = response["action"] as? String {
            if let result = fromAction(action) {
                return result
            }
        }

        if let message = response["log"] as? String {
            return .log(message)
        }

        return .error(.wrongMessageFormat)
    }

    private static func from(_ error: Int) -> HCaptchaDecoder.Result {
        switch error {
        case 1:
            .error(.htmlLoadError)

        case 7:
            .error(.networkError)

        case 15:
            .error(.sessionTimeout)

        case 29:
            .error(.failedSetup)

        case 31:
            .error(.rateLimit)

        case 30:
            .error(.challengeClosed)

        default:
            .error(.wrongMessageFormat)
        }
    }

    private static func fromAction(_ action: String) -> HCaptchaDecoder.Result? {
        switch action {
        case "showHCaptcha":
            .showHCaptcha

        case "didLoad":
            .didLoad

        case "onOpen":
            .onOpen

        case "onExpired":
            .onExpired

        case "onChallengeExpired":
            .onChallengeExpired

        case "onClose":
            .onClose

        default:
            nil
        }
    }
}
