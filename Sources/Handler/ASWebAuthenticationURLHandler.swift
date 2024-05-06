//
//  ASWebAuthenticationURLHandler.swift
//  OAuthSwift
//
//  Created by phimage on 01/11/2019.
//  Copyright © 2019 Dongri Jin, Marchand Eric. All rights reserved.
//

#if targetEnvironment(macCatalyst) || os(iOS)

import AuthenticationServices
import Foundation

@available(iOS 13.0, macCatalyst 13.0, *)
open class ASWebAuthenticationURLHandler: OAuthSwiftURLHandlerType {
    weak var presentationContextProvider: ASWebAuthenticationPresentationContextProviding?
    let prefersEphemeralWebBrowserSession: Bool
    let callbackUrl: URL
    
    private var webAuthSession: ASWebAuthenticationSession?

    public init(
        callbackUrl: URL,
        presentationContextProvider: ASWebAuthenticationPresentationContextProviding?,
        prefersEphemeralWebBrowserSession: Bool = false
    ) {
        self.callbackUrl = callbackUrl
        self.presentationContextProvider = presentationContextProvider
        self.prefersEphemeralWebBrowserSession = prefersEphemeralWebBrowserSession
    }

    public func handle(_ url: URL) {
        // swiftlint:disable force_unwrapping
        webAuthSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: callbackUrl.scheme!,
            completionHandler: { [weak self] callback, error in
                guard let self else { return }
                if let error = error, let url = self.makeErrorUrl(error: error) {
                    OAuthSwift.handle(url: url)
                } else if let successURL = callback {
                    OAuthSwift.handle(url: successURL)
                }
            }
        )
        // swiftlint:enable force_unwrapping
        webAuthSession?.presentationContextProvider = presentationContextProvider
        webAuthSession?.prefersEphemeralWebBrowserSession = prefersEphemeralWebBrowserSession

        _ = webAuthSession?.start()
    }
    
    func makeErrorUrl(error: Error) -> URL? {
        let msg = error.localizedDescription.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        let errorDomain = (error as NSError).domain
        let errorCode = (error as NSError).code
        let string = "\(callbackUrl.absoluteString)?error=\(msg ?? "UNKNOWN")&error_domain=\(errorDomain)&error_code=\(errorCode)"
        return URL(string: string)
    }
}

@available(iOS 13.0, macCatalyst 13.0, *)
extension ASWebAuthenticationURLHandler {
    static func isCancelledError(domain: String, code: Int) -> Bool {
        return domain == ASWebAuthenticationSessionErrorDomain &&
            code == ASWebAuthenticationSessionError.canceledLogin.rawValue
    }
}
#endif
