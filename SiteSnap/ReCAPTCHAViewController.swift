//
//  ReCAPTCHAViewController.swift
//  SiteSnap
//
//  Created by Paul Oprea on 24.02.2021.
//  Copyright © 2021 Paul Oprea. All rights reserved.
//

import UIKit
import WebKit

class ReCAPTCHAViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    static let identifier = "ReCAPTCHAPopup"
    private var webView: WKWebView!
    var viewModel: ReCAPTCHAViewModel?
    var activityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var popUpView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
//        navigationItem.leftBarButtonItem = UIBarButtonItem(
//            barButtonSystemItem: .cancel, target: self, action: #selector(didSelectCloseButton))
        popUpView.layer.cornerRadius = 8
        popUpView.layer.masksToBounds = true
        if let viewModel = viewModel{
            activityIndicator = UIActivityIndicatorView()
            activityIndicator.center = popUpView.convert(popUpView.center, from: popUpView.superview)
            activityIndicator.hidesWhenStopped = true
            activityIndicator.style = UIActivityIndicatorView.Style.gray
            
            
            webView.loadHTMLString(viewModel.html, baseURL: viewModel.url)
            webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            webView.center =  popUpView.convert(popUpView.center, from:popUpView.superview)
            popUpView.addSubview(webView)
            popUpView.addSubview(activityIndicator)
            
        }
    }
    
    func showActivityIndicator(show: Bool) {
        if show {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    override func loadView() {
        super.loadView()
        let webConfiguration = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        if let viewModel = viewModel{
            contentController.add(viewModel, name: "recaptcha")
            webConfiguration.userContentController = contentController
            webView = WKWebView(frame: popUpView.bounds, configuration: webConfiguration)
            webView.navigationDelegate = self
            webView.uiDelegate = self
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        showActivityIndicator(show: false)
    }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        showActivityIndicator(show: true)
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showActivityIndicator(show: false)
    }
}

//private extension ReCAPTCHAViewController {
//    @IBAction func didSelectCloseButton(){
//        dismiss(animated: true)
//    }
//}
