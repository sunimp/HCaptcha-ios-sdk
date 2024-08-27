//
//  HCaptchaWebViewManager.swift
//  HCaptcha

import Foundation
import WebKit

// MARK: - HCaptchaWebViewManager

/// Handles comunications with the webview containing the HCaptcha challenge.
class HCaptchaWebViewManager: NSObject {
    enum JSCommand: String {
        case execute = "execute();"
        case reset = "reset();"
    }

    typealias Log = HCaptchaLogger

    fileprivate enum Constants {
        static let BotUserAgent = "bot/2.1"
    }

    fileprivate let webViewInitSize = CGSize(width: 1, height: 1)

    #if DEBUG
    /// Forces the challenge to be explicitly displayed.
    var forceVisibleChallenge = false {
        didSet {
            webView.customUserAgent = forceVisibleChallenge ? Constants.BotUserAgent : nil
        }
    }

    /// Allows validation stubbing for testing
    public var shouldSkipForTests = false
    #endif

    /// True if validation  token was dematerialized
    var resultHandled = false

    /// Sends the result message
    var completion: ((HCaptchaResult) -> Void)?

    /// Called (currently) when a challenge becomes visible
    var onEvent: ((HCaptchaEvent, Any?) -> Void)?

    /// Notifies the JS bundle has finished loading
    var onDidFinishLoading: (() -> Void)? {
        didSet {
            if didFinishLoading {
                onDidFinishLoading?()
            }
        }
    }

    /// Configures the webview for display when required
    var configureWebView: ((WKWebView) -> Void)?

    /// The dispatch token used to ensure `configureWebView` is only called once.
    var configureWebViewDispatchToken = UUID()

    /// If the HCaptcha should be reset when it errors
    var shouldResetOnError = true

    /// The JS message recoder
    fileprivate var decoder: HCaptchaDecoder!

    /// Indicates if the script has already been loaded by the `webView`
    var didFinishLoading = false {
        didSet {
            if didFinishLoading {
                onDidFinishLoading?()
            }
        }
    }

    var loadingTimer: Timer?

    /// Stop async webView configuration
    private var stopInitWebViewConfiguration = false

    /// The observer for `.UIWindowDidBecomeVisible`
    fileprivate var observer: NSObjectProtocol?

    /// Base URL for WebView
    fileprivate var baseURL: URL!

    /// Actual HTML
    fileprivate var formattedHTML: String!

    /// Passive apiKey
    fileprivate var passiveApiKey: Bool

    /// Keep error If it happens before validate call
    fileprivate var lastError: HCaptchaError?

    /// Timeout to throw `.htmlLoadError` if no `didLoad` called
    fileprivate let loadingTimeout: TimeInterval

    /// The webview that executes JS code
    lazy var webView: WKWebView = {
        let debug = Log.minLevel == .debug
        let webview = WKWebView(
            frame: CGRect(origin: CGPoint.zero, size: webViewInitSize),
            configuration: self.buildConfiguration()
        )
        webview.accessibilityIdentifier = "webview"
        webview.accessibilityTraits = UIAccessibilityTraits.link
        webview.isHidden = true
        if debug {
            if #available(iOS 16.4, *) {
                webview.perform(Selector(("setInspectable:")), with: true)
            }
            webview.evaluateJavaScript("navigator.userAgent") { result, _ in
                Log.debug("WebViewManager WKWebView UserAgent: \(result ?? "nil")")
            }
        }
        Log.debug("WebViewManager WKWebView instance created")

        return webview
    }()

    /// Responsible for external link handling
    let urlOpener: HCaptchaURLOpener

    /// - parameters:
    ///    - `config`: HCaptcha config
    ///    - `urlOpener`:  class
    init(config: HCaptchaConfig, urlOpener: HCaptchaURLOpener = HCapchaAppURLOpener()) {
        Log.debug("WebViewManager.init")
        self.urlOpener = urlOpener
        baseURL = config.baseURL
        passiveApiKey = config.passiveApiKey
        loadingTimeout = config.loadingTimeout
        super.init()
        decoder = HCaptchaDecoder { [weak self] result in
            self?.handle(result: result)
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let arguments = [
                "apiKey": config.apiKey,
                "endpoint": config.actualEndpoint.absoluteString,
                "size": config.size.rawValue,
                "orientation": config.orientation.rawValue,
                "rqdata": config.rqdata ?? "",
                "theme": config.actualTheme,
                "debugInfo": HCaptchaDebugInfo.json,
            ]
            self.formattedHTML = String(format: config.html, arguments: arguments)
            Log.debug("WebViewManager.init formattedHTML built")
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                guard !stopInitWebViewConfiguration else { return }

                setupWebview(html: formattedHTML, url: baseURL)
            }
        }
    }

    /// - parameter view: The view that should present the webview.
    ///
    /// Starts the challenge validation
    func validate(on view: UIView) {
        Log.debug("WebViewManager.validate on: \(view)")
        resultHandled = false

        #if DEBUG
        guard !shouldSkipForTests else {
            completion?(HCaptchaResult(self, token: ""))
            return
        }
        #endif
        if !passiveApiKey {
            view.addSubview(webView)
            if didFinishLoading, webView.bounds.size == CGSize.zero || webView.bounds.size == webViewInitSize {
                doConfigureWebView()
            }
        }

        executeJS(command: .execute)
    }

    /// Stops the execution of the webview
    func stop() {
        Log.debug("WebViewManager.stop")
        stopInitWebViewConfiguration = true
        webView.stopLoading()
        resultHandled = true
        loadingTimer?.invalidate()
        loadingTimer = nil
    }

    /// Resets the HCaptcha.
    ///
    /// The reset is achieved by calling `ghcaptcha.reset()` on the JS API.
    func reset() {
        Log.debug("WebViewManager.reset")
        configureWebViewDispatchToken = UUID()
        stopInitWebViewConfiguration = false
        resultHandled = false
        if didFinishLoading {
            executeJS(command: .reset)
            didFinishLoading = false
        } else if let formattedHTML {
            setupWebview(html: formattedHTML, url: baseURL)
        }
    }
}

// MARK: - Private Methods

/// Private methods for HCaptchaWebViewManager
extension HCaptchaWebViewManager {
    /// - returns: An instance of `WKWebViewConfiguration`
    ///
    /// Creates a `WKWebViewConfiguration` to be added to the `WKWebView` instance.
    private func buildConfiguration() -> WKWebViewConfiguration {
        let controller = WKUserContentController()
        controller.add(decoder, name: "hcaptcha")

        let conf = WKWebViewConfiguration()
        conf.userContentController = controller

        return conf
    }

    /// - parameter result: A `HCaptchaDecoder.Result` with the decoded message.
    ///
    /// Handles the decoder results received from the webview
    private func handle(result: HCaptchaDecoder.Result) {
        Log.debug("WebViewManager.handleResult: \(result)")

        guard !resultHandled else {
            Log.debug("WebViewManager.handleResult skip as handled")
            return
        }

        switch result {
        case .token(let token):
            completion?(HCaptchaResult(self, token: token))

        case .error(let error):
            handle(error: error)
            onEvent?(.error, error)

        case .showHCaptcha: webView.isHidden = false

        case .didLoad: didLoad()

        case .onOpen: onEvent?(.open, nil)

        case .onExpired: onEvent?(.expired, nil)

        case .onChallengeExpired: onEvent?(.challengeExpired, nil)

        case .onClose: onEvent?(.close, nil)

        case .log: break
        }
    }

    private func handle(error: HCaptchaError) {
        loadingTimer?.invalidate()
        loadingTimer = nil
        if error == .sessionTimeout {
            if shouldResetOnError, let view = webView.superview {
                reset()
                validate(on: view)
            } else {
                completion?(HCaptchaResult(self, error: error))
            }
        } else {
            if let completion {
                completion(HCaptchaResult(self, error: error))
            } else {
                lastError = error
            }
        }
    }

    private func didLoad() {
        Log.debug("WebViewManager.didLoad")
        if completion != nil {
            executeJS(command: .execute, didLoad: true)
        }
        didFinishLoading = true
        loadingTimer?.invalidate()
        loadingTimer = nil
        doConfigureWebView()
    }

    private func doConfigureWebView() {
        Log.debug("WebViewManager.doConfigureWebView")
        if configureWebView != nil, !passiveApiKey {
            DispatchQueue.once(token: configureWebViewDispatchToken) { [weak self] in
                guard let self else { return }
                configureWebView?(webView)
            }
        }
    }

    /// - parameters:
    ///    - html: The embedded HTML file
    ///    - url: The base URL given to the webview
    ///
    /// Adds the webview to a valid UIView and loads the initial HTML file
    private func setupWebview(html: String, url: URL) {
        var keyWindow: UIWindow?
        let allScenes = UIApplication.shared.connectedScenes
        for scene in allScenes {
            guard let windowScene = scene as? UIWindowScene else {
                continue
            }
            for window in windowScene.windows where window.isKeyWindow {
                keyWindow = window
            }
        }
        if let window = keyWindow {
            setupWebview(on: window, html: html, url: url)
        } else {
            observer = NotificationCenter.default.addObserver(
                forName: UIWindow.didBecomeVisibleNotification,
                object: nil,
                queue: nil
            ) { [weak self] notification in
                guard let window = notification.object as? UIWindow else { return }
                guard let slf = self else { return }
                slf.setupWebview(on: window, html: html, url: url)
            }
        }
    }

    /// - parameters:
    ///    - window: The window in which to add the webview
    ///    - html: The embedded HTML file
    ///    - url: The base URL given to the webview
    ///
    /// Adds the webview to a valid UIView and loads the initial HTML file
    private func setupWebview(on window: UIWindow, html: String, url: URL) {
        Log.debug("WebViewManager.setupWebview")
        if webView.superview == nil {
            window.addSubview(webView)
        }
        webView.loadHTMLString(html, baseURL: url)
        if webView.navigationDelegate == nil {
            webView.navigationDelegate = self
        }
        loadingTimer?.invalidate()
        loadingTimer = Timer.scheduledTimer(withTimeInterval: loadingTimeout, repeats: false, block: { _ in
            self.handle(error: .htmlLoadError)
            self.loadingTimer = nil
        })

        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// - parameters:
    ///    - command: The JavaScript command to be executed
    ///    - didLoad: True if didLoad event already occured
    ///
    /// Executes the JS command that loads the HCaptcha challenge. This method has no effect if the webview hasn't
    /// finished loading.
    private func executeJS(command: JSCommand, didLoad: Bool = false) {
        Log.debug("WebViewManager.executeJS: \(command)")
        guard didLoad else {
            if let error = lastError {
                loadingTimer?.invalidate()
                loadingTimer = nil
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    Log.debug("WebViewManager complete with pendingError: \(error)")

                    completion?(HCaptchaResult(self, error: error))
                    lastError = nil
                }
                if error == .networkError {
                    Log.debug("WebViewManager reloads html after \(error) error")
                    webView.loadHTMLString(formattedHTML, baseURL: baseURL)
                }
            }
            return
        }
        webView.evaluateJavaScript(command.rawValue) { [weak self] _, error in
            if let error {
                self?.decoder.send(error: .unexpected(error))
            }
        }
    }

    private func executeJS(command: JSCommand) {
        executeJS(command: command, didLoad: didFinishLoading)
    }
}
