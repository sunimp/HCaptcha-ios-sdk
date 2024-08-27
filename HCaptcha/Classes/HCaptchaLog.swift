//
//  HCaptchaEvent.swift
//  HCaptcha
//
//  Copyright © 2023 HCaptcha. All rights reserved.
//

import Foundation

// MARK: - HCaptchaLogLevel

/// Internal SDK logger level
enum HCaptchaLogLevel: Int, CustomStringConvertible {
    case debug = 0
    case warning = 1
    case error = 2

    var description: String {
        switch self {
        case .debug:
            "Debug"
        case .warning:
            "Warning"
        case .error:
            "Error"
        }
    }
}

// MARK: - HCaptchaLogger

/// Internal SDK logger
class HCaptchaLogger {
    static var minLevel: HCaptchaLogLevel = .error

    static func debug(_ message: String, _ args: CVarArg...) {
        log(level: .debug, message: message, args: args)
    }

    static func warn(_ message: String, _ args: CVarArg...) {
        log(level: .warning, message: message, args: args)
    }

    static func error(_ message: String, _ args: CVarArg...) {
        log(level: .error, message: message, args: args)
    }

    static func log(level: HCaptchaLogLevel, message: String, args: [CVarArg]) {
        #if DEBUG
        guard level.rawValue >= minLevel.rawValue else {
            return
        }

        let formattedMessage = String(format: message, arguments: args)
        let logMessage = "\(timestamp) \(threadID) HCaptcha/\(level.description): \(formattedMessage)"

        print(logMessage)
        #endif
    }

    private static var timestamp: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.sss"
        return dateFormatter.string(from: Date())
    }

    private static var threadID: String {
        Thread.isMainThread ? "main" : "\(pthread_self())"
    }
}
