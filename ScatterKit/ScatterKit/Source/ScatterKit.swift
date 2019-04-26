//
//  ScatterKit.swift
//  ScatterKit
//
//  Created by Alex Melnichuk on 3/9/19.
//  Copyright © 2019 Baltic International Group OU. All rights reserved.
//

import UIKit
import WebKit

public class ScatterKit {
    public var delegate: ScatterKitDelegate? {
        get {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            return _delegate
        }
        set {
            objc_sync_enter(self)
            _delegate = newValue
            objc_sync_exit(self)
        }
    }
    
    private weak var _delegate: ScatterKitDelegate?
    private weak var webView: WKWebView?
    private var scriptDelegate: ScriptMessageHandlerProxy!
    private let queue: DispatchQueue
    private let delegateQueue: DispatchQueue
    
    public init(webView: WKWebView,
                queue: DispatchQueue = DispatchQueue(label: "ScatterKit.background", attributes: .concurrent),
                delegateQueue: DispatchQueue = .main) {
        self.webView = webView
        self.queue = queue
        self.delegateQueue = delegateQueue
        self.scriptDelegate = ScriptMessageHandlerProxy(parent: self)
        injectJS()
        registerScripts()
    }
    
    deinit {
        #if DEBUG
        print("\(ScatterKit.self): 🗑 deinit \(self)")
        #endif
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "pushMessage")
    }
    
    private func registerScripts() {
        let delegate = ScriptMessageHandlerLeakAvoider(delegate: scriptDelegate)
        webView?.configuration.userContentController.add(delegate, name: "pushMessage")
    }
    
    private func injectJS() {
        let userAgent = webView?.customUserAgent?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let scatterBundlePath = Bundle(for: ScatterKit.self).path(forResource: "ScatterKit", ofType: "bundle")!
        let scriptPath = Bundle(path: scatterBundlePath)!.path(forResource: "scatterkit_script", ofType: "js")!
        var content = try! String(contentsOfFile: scriptPath)
        
        let scriptString = """
        var SP_SCRIPT = document.createElement('script');
        var SP_USER_AGENT_ANDROID = "SP_USER_AGENT_ANDROID";
        var SP_USER_AGENT_IOS = '\(userAgent)';
        var SP_TIMEOUT = \(60 * 1000);
        SP_SCRIPT.type = 'text/javascript';
        SP_SCRIPT.text = \"
        """
        content.insert(contentsOf: scriptString, at: content.startIndex)
        let end = content.index(before: content.endIndex)
        content.insert(contentsOf: "\";document.getElementsByTagName('head')[0].appendChild(SP_SCRIPT);", at: end)
        #if DEBUG
        print("__SCATTER: content: \(content)")
        #endif
        let script = WKUserScript(source: content, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webView?.configuration.userContentController.addUserScript(script)
    }
    
    fileprivate func handleScriptMessage(_ message: WKScriptMessage) {
        #if DEBUG
        print("__SCATTER: name: \(message.name), body: \(message.body)")
        #endif
        let body = message.body
        queue.async { [weak self] in
            guard let string = body as? String else {
                return
            }
            let data = Data(string.utf8)
//            guard let dict = body as? [String: Any],
//                let data = try? JSONSerialization.data(withJSONObject: dict, options: []) else {
//                    return
//            }
        
            let request: Request
            do {
                request = try JSONDecoder().decode(Request.self, from: data)
            } catch {
                #if DEBUG
                print("__SCATTER: request error: \(error)")
                #endif
                self?.asyncError(error, during: .request)
                return
            }

            // send error when request arguments werent parsed properly
            guard let params = request.params else {
                let errorMessage = "Unable to parse model for \(request.methodName)"
                let error = ScatterKitError.parse(message: errorMessage)
                let response = Response(request: request, code: .error, data: .error(error), message: errorMessage)
                self?.sendResponse(response)
                return
            }
            
            guard let self = self else { return }
            switch params {
            case .appInfo:
                let callback: SKCallback<Response.AppInfo> = self.makeResultCallback(request: request) {
                    Response(request: request, code: .success, data: .appInfo($0), message: .success)
                }
                self.asyncCallDelegate(request) { try $0.scatterDidRequestAppInfo(callback) }
            case .walletLanguage:
                let callback: SKCallback<String> = self.makeResultCallback(request: request) {
                    Response(request: request, code: .success, data: .walletLanguage(language: $0), message: .success)
                }
                self.asyncCallDelegate(request) { try $0.scatterDidRequestWalletLanguage(callback) }
            case .eosAccount:
                let callback: SKCallback<String> = self.makeResultCallback(request: request) {
                    Response(request: request, code: .success, data: .eosAccount(name: $0), message: .success)
                }
                self.asyncCallDelegate(request) { try $0.scatterDidRequestAccountName(callback) }
            case .eosBalance(let balance):
                let callback: SKCallback<Response.EOSBalance> = self.makeResultCallback(request: request) {
                    Response(request: request, code: .success, data: .eosBalance($0), message: .success)
                }
                self.asyncCallDelegate(request) { try $0.scatterDidRequestBalance(balance, completionHandler: callback) }
            case .walletWithAccount:
                let callback: SKCallback<Response.WalletWithAccount> = self.makeResultCallback(request: request) {
                    Response(request: request, code: .success, data: .walletWithAccount($0), message: .success)
                }
                self.asyncCallDelegate(request) { try $0.scatterDidRequestWalletWithAccount(callback) }
            case .pushActions(let actions):
                let callback: SKCallback<Response.Transaction> = self.makeResultCallback(request: request) {
                    Response(request: request, code: .success, data: .pushActions($0), message: .success)
                }
                self.asyncCallDelegate(request) { try $0.scatterDidRequestTransaction(with: actions, completionHandler: callback) }
            case .pushTransfer(let transfer):
                let callback: SKCallback<Response.Transaction> = self.makeResultCallback(request: request) {
                    Response(request: request, code: .success, data: .pushTransfer($0), message: .success)
                }
                self.asyncCallDelegate(request) { try $0.scatterDidRequestTransfer(transfer, completionHandler: callback) }
            case .transactionSignature(let transaction):
                let callback: SKCallback<Response.TransactionSignature> = self.makeResultCallback(request: request) {
                    Response(request: request, code: .success, data: .transactionSignature($0), message: .success)
                }
                self.asyncCallDelegate(request) { try $0.scatterDidRequestTransactionSignature(transaction, completionHandler: callback) }
            case .messageSignature(let message):
                let callback: SKCallback<Response.MessageSignature> = self.makeResultCallback(request: request) {
                    Response(request: request, code: .success, data: .messageSignature($0), message: .success)
                }
                self.asyncCallDelegate(request) { try $0.scatterDidRequestMessageSignature(message, completionHandler: callback) }
            }
        }
    }
    
    private func makeResultCallback<T>(request: Request, parseResponse: @escaping (T) throws -> Response) -> SKCallback<T> {
        return { [weak self] result in
            self?.queue.async {
                let response: Response
                switch result {
                case .success(let success):
                    do {
                        response = try parseResponse(success)
                    } catch {
                        let errorMessage = "Error when transforming response for request \(request)"
                        let error = ScatterKitError.parse(message: errorMessage)
                        response = Response(request: request, code: .error, data: .error(error), message: errorMessage)
                    }
                case .error(let error):
                    let errorMessage = "\(error)"
                    response = Response(request: request, code: .error, data: .error(error), message: errorMessage)
                }
                self?.sendResponse(response)
            }
        }
    }
    
    private func sendResponse(_ response: Response) {
        do {
            let encoder = JSONEncoder()
            let responseData: Data
            do {
                responseData = try encoder.encode(response)
            } catch {
                let errorMessage = "Error \(error) when encoding response \(response)"
                let response = Response(request: response.request, code: .error, data: .error(error), message: errorMessage)
                responseData = try encoder.encode(response)
            }
            let json = String(bytes: responseData, encoding: .utf8)!
            let js = String(format: "%@('%@')", response.request.methodName.rawValue, json)
            //let js = String(format: "%@('%@','%@')", "callbackResult", request.serialNumber, json)
            #if DEBUG
            print("__SCATTER: javascript: \(js)")
            #endif
            DispatchQueue.main.async { [weak self] in
                self?.webView?.evaluateJavaScript(js) { result, error in
                    if let error = error {
                        self?.asyncError(error, during: .javascriptEvaluation)
                    }
                    #if DEBUG
                    print("__SCATTER: evaluated: \(result), \(error) using: \(js)")
                    #endif
                }
            }
            if case let .error(error) = response.data {
                self.asyncError(error, during: .callback)
            }
        } catch {
            self.asyncError(error, during: .response)
        }
    }
    
    private func asyncCallDelegate(_ request: Request, delegateCallback: @escaping (ScatterKitDelegate) throws -> Void) {
        delegateQueue.async { [weak self] in
            do {
                // send callback to delegate
                if let delegate = self?.delegate {
                    try delegateCallback(delegate)
                }
            } catch {
                // client thrown error, handle error
                let errorMessage = "Error when calling delegate method for \(request)"
                let error = ScatterKitError.result(error)
                let response = Response(request: request, code: .error, data: .error(error), message: errorMessage)
                self?.sendResponse(response)
            }
        }
    }

    private func asyncError(_ error: Error, during lifetime: ScatterKitError.Lifetime) {
        delegateQueue.async { [weak delegate] in
            delegate?.scatter(didReceive: error, during: lifetime)
        }
    }
}


extension ScatterKit {
    public struct ProtocolInfo {
        static let name = "Scatter Plugin"
        static let version = "1.0.0"
    }
}

fileprivate class ScriptMessageHandlerProxy: NSObject, WKScriptMessageHandler {
    
    private unowned let parent: ScatterKit
    
    init(parent: ScatterKit) {
        self.parent = parent
    }
    
    deinit {
        #if DEBUG
        print("\(ScatterKit.self): 🗑 deinit \(self)")
        #endif
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        parent.handleScriptMessage(message)
    }
}

fileprivate class ScriptMessageHandlerLeakAvoider: NSObject, WKScriptMessageHandler {
    
    private weak var delegate: WKScriptMessageHandler?
    
    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
        super.init()
    }
    
    deinit {
        #if DEBUG
        print("\(ScatterKit.self): 🗑 deinit \(self)")
        #endif
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}

fileprivate extension String {
    static var success: String {
        return "success"
    }
}
