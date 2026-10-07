import Foundation
import UIKit
import AuthenticationServices

/// OAuth uses the system authentication browser, never an embedded WebView.
@objc(BiscaAuthNative) public final class BiscaAuthNative: NSObject, ASWebAuthenticationPresentationContextProviding, @unchecked Sendable {
    @objc public static let shared = BiscaAuthNative()
    private let lock = NSLock()
    private var result = ""
    @MainActor private var session: ASWebAuthenticationSession?
    @MainActor private var generation = 0
    private func finish(_ value: String) {
        lock.lock(); result = value; lock.unlock()
    }
    @objc public func drain() -> String {
        lock.lock(); defer { lock.unlock() }
        let value = result; result = ""; return value
    }
    @objc public func open(_ value: String) {
        DispatchQueue.main.async {
            self.generation += 1
            let attempt = self.generation
            self.session?.cancel()
            self.finish("")
            guard let url = URL(string: value), url.scheme == "https" else { self.finish("error"); return }
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "com.bisca.game") { url, error in
                DispatchQueue.main.async {
                    guard attempt == self.generation else { return }
                    self.session = nil
                    self.finish(url?.absoluteString ?? (error == nil ? "error" : "cancel"))
                }
            }
            session.presentationContextProvider = self
            self.session = session
            if !session.start() { self.session = nil; self.finish("error") }
        }
    }
    @objc public func cancel() {
        DispatchQueue.main.async {
            self.generation += 1
            self.session?.cancel(); self.session = nil; self.finish("")
        }
    }
    @MainActor public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
