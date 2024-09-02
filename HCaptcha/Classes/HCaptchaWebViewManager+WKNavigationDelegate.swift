//
//  HCaptchaWebViewManager+WKNavigationDelegate.swift
//
//  Created by Sun on 2024/4/18.
//

import Foundation
import WebKit

extension HCaptchaWebViewManager: WKNavigationDelegate {
    func webView(
        _: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url, urlOpener.canOpenURL(url) {
            urlOpener.openURL(url)
        }
        decisionHandler(WKNavigationActionPolicy.allow)
    }

    /// Tells the delegate that an error occurred during navigation.
    func webView(_: WKWebView, didFail _: WKNavigation!, withError error: Error) {
        Log.debug("WebViewManager.webViewDidFail with \(error)")
        completion?(HCaptchaResult(self, error: .unexpected(error)))
    }

    /// Tells the delegate that an error occurred during the early navigation process.
    func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
        Log.debug("WebViewManager.webViewDidFailProvisionalNavigation with \(error)")
        completion?(HCaptchaResult(self, error: .unexpected(error)))
    }

    /// Tells the delegate that the web view’s content process was terminated.
    func webViewWebContentProcessDidTerminate(_: WKWebView) {
        Log.debug("WebViewManager.webViewWebContentProcessDidTerminate")
        let kHCaptchaErrorWebViewProcessDidTerminate = -1
        let kHCaptchaErrorDomain = "com.hcaptcha.sdk-ios"
        let error = NSError(
            domain: kHCaptchaErrorDomain,
            code: kHCaptchaErrorWebViewProcessDidTerminate,
            userInfo: [
                NSLocalizedDescriptionKey: "WebView web content process did terminate",
                NSLocalizedRecoverySuggestionErrorKey: "Call HCaptcha.reset()",
            ]
        )
        completion?(HCaptchaResult(self, error: .unexpected(error)))
        didFinishLoading = false
    }
}
