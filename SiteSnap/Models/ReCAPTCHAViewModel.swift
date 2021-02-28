//
//  ReCAPTCHAViewModel.swift
//  SiteSnap
//
//  Created by Paul Oprea on 24.02.2021.
//  Copyright © 2021 Paul Oprea. All rights reserved.
//

import WebKit

protocol ReCAPTCHAViewModelDelegate: class {
    func didSolveCAPTCHA(token: String)
}

class ReCAPTCHAViewModel: NSObject {
    weak var delegate: ReCAPTCHAViewModelDelegate?
    
    var html: String {
        guard let filePath = Bundle.main.path(forResource: "recaptcha", ofType: "html") else {
            assertionFailure("Unable to find the file.")
            return ""
        }
        let contents = try! String(contentsOfFile: filePath, encoding: .utf8)
        return parse(contents, with: ["siteKey": siteKey])
    }
    
    let siteKey: String
    let url: URL
    
    /// Creates a ReCAPTCHAViewModel
    /// - Parameters:
    ///   - siteKey: ReCAPTCHA's site key
    ///   - url: The URL for registered with Google
    
    init(siteKey: String, url: URL) {
        self.siteKey = siteKey
        self.url = url
        super.init()
    }
}

extension ReCAPTCHAViewModel: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let message = message.body as? String else {
            assertionFailure("Expected a string")
            return
        }
        delegate?.didSolveCAPTCHA(token: message)
    }
}

private extension ReCAPTCHAViewModel {
    func parse(_ string: String, with valueMap: [String: String]) -> String {
        var parsedString = string
        
        valueMap.forEach { key, value in
            parsedString = parsedString.replacingOccurrences(of: "${\(key)}", with: value)
        }
        
        return parsedString
    }
}
