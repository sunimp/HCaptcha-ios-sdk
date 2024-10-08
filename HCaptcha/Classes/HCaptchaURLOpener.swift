//
//  HCaptchaURLOpener.swift
//
//  Created by Sun on 2022/10/25.
//

import Foundation
import UIKit

// MARK: - HCaptchaURLOpener

/// The protocol for a contractor which can handle/open URLs in an external viewer/browser
protocol HCaptchaURLOpener {
    /// Return true if url can be handled
    /// - parameter url: The URL to be checked
    func canOpenURL(_ url: URL) -> Bool

    /// Handle passed url
    /// - parameter url: The URL to be checked
    func openURL(_ url: URL)
}

// MARK: - HCapchaAppURLOpener

/// UIApplication based implementation
class HCapchaAppURLOpener: HCaptchaURLOpener {
    func canOpenURL(_ url: URL) -> Bool {
        UIApplication.shared.canOpenURL(url)
    }

    func openURL(_ url: URL) {
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
}
