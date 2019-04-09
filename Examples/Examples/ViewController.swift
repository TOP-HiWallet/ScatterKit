//
//  ViewController.swift
//  Examples
//
//  Created by Alex Melnichuk on 11/12/18.
//  Copyright © 2018 Baltic International Group OU. All rights reserved.
//

import UIKit
import WebKit
import ScatterKit

class ViewController: UIViewController {

    private var webView: WKWebView!
    private var scatterKit: ScatterKit!
    
    // Your decoded private key
    private let privateKey = Data()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        
        self.webView = WKWebView(frame: view.bounds, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.customUserAgent = "Examples_iOS"
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        scatterKit = ScatterKit(webView: webView)
        scatterKit.delegate = self
        
        let url = URL(string: "https://betdice.one/")!
        webView.load(URLRequest(url: url))
    }
}

extension ViewController: ScatterKitDelegate {
    func scatterDidRequestAccountName(_ completionHandler: @escaping SKCallback<String>) throws {
        completionHandler(.success("myeosaccount"))
    }
    
    
    func scatterDidRequestMessageSignature(_ request: ScatterKit.Request.MessageSignature, completionHandler: @escaping SKCallback<ScatterKit.Response.MessageSignature>) throws {
        typealias MessageSignature = ScatterKit.Response.MessageSignature
        do {
            var data = Data(request.data.utf8)
            if !request.isHash {
                data = Crypto.sha256(data)
            }
            let signature = try Crypto.sign(privateKey: privateKey, sha256Digest: data)
            let response = MessageSignature(message: "Success!", signature: signature)
            completionHandler(.success(response))
        } catch {
            let signatureError = SignatureError()
            completionHandler(.error(signatureError))
        }
    }
    
    func scatterDidRequestTransactionSignature(_ request: ScatterKit.Request.TransactionSignature, completionHandler: @escaping SKCallback<ScatterKit.Response.TransactionSignature>) throws {
        typealias TransactionSignature = ScatterKit.Response.TransactionSignature
        do {
            let transaction = try Crypto.transaction(request, privateKey: privateKey)
            let signatureInfo = TransactionSignature(signatures: transaction.signatures, returnedFields: [:])
            completionHandler(.success(signatureInfo))
        } catch {
            let signatureError = SignatureError()
            completionHandler(.error(signatureError))
        }
    }
}
