//
//  HCaptcha+Rx.swift
//
//  Created by Sun on 2020/6/25.
//

import RxSwift
import UIKit
#if SWIFT_PACKAGE
import HCaptcha
#endif

/// Provides a public extension on HCaptcha that makes it reactive.
extension Reactive where Base: HCaptcha {
    /// Returns observable which allows to listen for different events from SDK
    public func events() -> Observable<(HCaptchaEvent, Any?)> {
        Observable<(HCaptchaEvent, Any?)>.create { [weak base] observer -> Disposable in
            base?.onEvent { event, data in
                observer.onNext((event, data))
            }

            return Disposables.create {
                observer.onCompleted()
                base?.onEvent(nil)
            }
        }
    }

    /// - parameters:
    ///   - view: The view that should present the webview.
    ///   - resetOnError: If HCaptcha should be reset if it errors. Defaults to `true`
    ///
    /// Starts the challenge validation uppon subscription.
    ///
    /// The stream's element is a String with the validation token.
    ///
    /// Sends `stop()` uppon disposal.
    ///
    /// - See: `HCaptcha.validate(on:resetOnError:completion:)`
    /// - See: `HCaptcha.stop()`
    public func validate(on view: UIView, resetOnError: Bool = true) -> Observable<String> {
        Single<String>.create { [weak base] single in
            base?.validate(on: view, resetOnError: resetOnError) { result in
                do {
                    try single(.success(result.dematerialize()))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create { [weak base] in
                base?.stop()
            }
        }
        .asObservable()
    }

    /// Resets the HCaptcha.
    ///
    /// The reset is achieved by calling `ghcaptcha.reset()` on the JS API.
    ///
    /// - See: `HCaptcha.reset()`
    public var reset: AnyObserver<Void> {
        AnyObserver { [weak base] event in
            guard case .next = event else {
                return
            }

            base?.reset()
        }
    }

    /// Notifies when the webview finishes loading all JS resources
    ///
    /// This Observable may produce multiple events since the resources may be loaded multiple times in
    /// case of error or reset. This may also immediately produce an event if the resources have
    /// already finished loading when you subscribe to this Observable.
    public var didFinishLoading: Observable<Void> {
        Observable.create { [weak base] (observer: AnyObserver<Void>) in
            base?.didFinishLoading { observer.onNext(()) }

            return Disposables.create { [weak base] in
                base?.didFinishLoading(nil)
            }
        }
    }
}
