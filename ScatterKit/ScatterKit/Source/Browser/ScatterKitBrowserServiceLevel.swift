//
//  ScatterKitBrowserServiceLevel.swift
//  scatter2
//
//  Created by Alex Melnichuk on 5/28/19.
//  Copyright © 2019 Alex Melnichuk. All rights reserved.
//

import UIKit
import WebKit

class ScatterKitBrowserServiceLevel: ScatterKitServiceLevelProtocol, ScatterKitScriptMessageHandlerProxyDelegate {
    typealias ServiceLevelRequest = ScatterKit.Request
    typealias ServiceLevelResponse = ScatterKit.Response
    typealias ServiceLevelError = ScatterKit.Response
    
    let queue: DispatchQueue
    let delegateQueue: DispatchQueue
    
    var scriptDelegate: ScatterKitScriptMessageHandlerProxy!
    weak var webView: WKWebView?
    weak var delegate: ScatterKitDelegate?
    
    private var apiHostLevel: ScatterKitBrowserApiHostLevel!
    
    public init(webView: WKWebView,
                queue: DispatchQueue = DispatchQueue(label: "ScatterKit.Browser.background", attributes: .concurrent),
                delegateQueue: DispatchQueue = .main) {
        self.webView = webView
        self.queue = queue
        self.delegateQueue = delegateQueue
        self.scriptDelegate = ScatterKitScriptMessageHandlerProxy(parent: self)
        self.apiHostLevel = ScatterKitBrowserApiHostLevel(serviceLevel: self)
        
        hook()
        setup()
    }
    
    deinit {
        unhook()
    }
    
    func hook() {
        let delegate = ScatterKitScriptMessageHandlerLeakAvoider(delegate: scriptDelegate)
        webView?.configuration.userContentController.add(delegate, name: "pushMessage")
    }
    
    func unhook() {
        #if DEBUG
        print("\(ScatterKit.self): 🗑 deinit \(self)")
        #endif
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "pushMessage")
    }
    
    func setup() {
        let userAgent = webView?.customUserAgent?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let bundlePath = Bundle(for: ScatterKit.self).path(forResource: "ScatterKit", ofType: "bundle")!
        let scriptPath = Bundle(path: bundlePath)!.path(forResource: "scatterkit_browser", ofType: "js")!
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
        print("\(ScatterKit.self): content: \(content)")
        #endif
        let script = WKUserScript(source: content, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webView?.configuration.userContentController.addUserScript(script)
    }
    
    func readMessageLevelRequest(_ message: String) throws -> ServiceLevelRequest {
        return try JSONDecoder().decode(ScatterKit.Request.self, from: Data(message.utf8))
    }
    
    func sendHostLevelRequest(_ request: ServiceLevelRequest) throws {
        try? apiHostLevel.sendClientLevelRequest(request, serviceRequest: request)
    }
    
    func sendMessageLevelResponse(_ response: ServiceLevelResponse) throws {
        let encoder = JSONEncoder()
        let responseData: Data
        do {
            responseData = try encoder.encode(response)
        } catch {
            #if DEBUG
            print("\(ScatterKit.self): browser response error: \(error)")
            #endif
            return
        }
        let json = String(bytes: responseData, encoding: .utf8)!
        let callback = response.request.callback
        let js = String(format: "%@('%@')", callback, json)
        #if DEBUG
        print("\(ScatterKit.self): browser javascript: \(js)")
        #endif
        DispatchQueue.main.async { [weak self] in
            self?.webView?.evaluateJavaScript(js) { result, error in
                #if DEBUG
                print("\(ScatterKit.self): browser evaluated: \(String(describing: result)), \(String(describing: error)) using: \(js)")
                #endif
            }
        }
    }
    
    func sendMessageLevelError(_ error: ServiceLevelResponse) throws {
        try sendMessageLevelResponse(error)
    }
    
    func handleScriptMessage(_ message: WKScriptMessage) {
        handleMessage(message.body)
    }
}

