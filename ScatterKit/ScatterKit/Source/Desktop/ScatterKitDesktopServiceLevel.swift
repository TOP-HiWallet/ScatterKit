//
//  ScatterKitDesktopLevel.swift
//  scatter2
//
//  Created by Alex Melnichuk on 5/28/19.
//  Copyright © 2019 Alex Melnichuk. All rights reserved.
//

import UIKit
import WebKit

class ScatterKitDesktopServiceLevel: ScatterKitServiceLevelProtocol, ScatterKitScriptMessageHandlerProxyDelegate {
    typealias ServiceLevelError = ServiceLevelResponse
    
    enum Header: String, Codable {
        case connect = "40/scatter"
        case event = "42/scatter"
    }
    
    let queue: DispatchQueue
    let delegateQueue: DispatchQueue
    
    var scriptDelegate: ScatterKitScriptMessageHandlerProxy!
    weak var webView: WKWebView?
    weak var delegate: ScatterKitDelegate?
    
    private var apiHostLevel: ScatterKitDesktopApiHostLevel!
    
    public init(webView: WKWebView,
                queue: DispatchQueue = DispatchQueue(label: "ScatterKit.Desktop.background", attributes: .concurrent),
                delegateQueue: DispatchQueue = .main) {
        self.webView = webView
        self.queue = queue
        self.delegateQueue = delegateQueue
        self.scriptDelegate = ScatterKitScriptMessageHandlerProxy(parent: self)
        self.apiHostLevel = ScatterKitDesktopApiHostLevel(serviceLevel: self)
        
        hook()
        setup()
    }
    
    deinit {
        unhook()
    }
    
    func hook() {
        let delegate = ScatterKitScriptMessageHandlerLeakAvoider(delegate: scriptDelegate)
        webView?.configuration.userContentController.add(delegate, name: "scatterKit")
    }
    
    func unhook() {
        #if DEBUG
        print("\(ScatterKit.self): 🗑 deinit \(self)")
        #endif
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "scatterKit")
    }
    
    func setup() {
        let bundlePath = Bundle(for: ScatterKit.self).path(forResource: "ScatterKit", ofType: "bundle")!
        let scriptPath = Bundle(path: bundlePath)!.path(forResource: "scatterkit_desktop", ofType: "js")!
        let js = try! String(contentsOfFile: scriptPath)
        let script = WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        webView?.configuration.userContentController.addUserScript(script)
    }
    
    func readMessageLevelRequest(_ message: String) throws -> ServiceLevelRequest {
        return try JSONDecoder().decode(ServiceLevelRequest.self, from: Data(message.utf8))
    }
    
    func sendHostLevelRequest(_ request: ServiceLevelRequest) throws {
        switch request.kind {
        case .api(let api)?:
            try? apiHostLevel.sendClientLevelRequest(api, serviceRequest: request)
        default:
            break
        }
    }
    
    func sendMessageLevelResponse(_ response: ServiceLevelResponse) throws {
        let encoder = JSONEncoder()
        let responseData: Data
        do {
            responseData = try encoder.encode(response)
        } catch {
            #if DEBUG
            print("\(ScatterKit.self): desktop response error: \(error)")
            #endif
            return
        }
        let callback = response.request.callback
        let header = response.header.rawValue
        let response = String(bytes: responseData, encoding: .utf8)!
        let string = "\(header),\(response)"
        let js = String(format: "%@('%@','%@')", callback, "message", string)
        #if DEBUG
        print("\(ScatterKit.self): desktop javascript: \(js)")
        #endif
        DispatchQueue.main.async { [weak self] in
            self?.webView?.evaluateJavaScript(js) { result, error in
                #if DEBUG
                print("\(ScatterKit.self): desktop evaluated: \(String(describing: result)), \(String(describing: error)) using: \(js)")
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

// MARK: - ScatterKitDesktopLevel+Request

extension ScatterKitDesktopServiceLevel {
    struct ServiceLevelRequest {
        enum Kind {
            case api(ScatterKitDesktopApiHostLevel.HostLevelRequest)
            
            enum Name: String, Decodable {
                case disconnect
                case rekeyed
                case event
                case api
                case pair
            }
        }
        
        let header: Header
        let kind: Kind?
        let callback: String
    }
}

extension ScatterKitDesktopServiceLevel.ServiceLevelRequest: Decodable {
    enum CodingKeys: String, CodingKey {
        case header
        case type
        case request
        case callback
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.header = try container.decode(ScatterKitDesktopServiceLevel.Header.self, forKey: .header)
        self.callback = try container.decode(String.self, forKey: .callback)
        
        let typeName = try container.decodeIfPresent(Kind.Name.self, forKey: .type)
        switch (header, typeName) {
        case (.event, .api?):
            let api = try container.decode(ScatterKitDesktopApiHostLevel.HostLevelRequest.self, forKey: .request)
            self.kind = .api(api)
        default:
            throw DecodingError.dataCorruptedError(forKey: .request,
                                                   in: container,
                                                   debugDescription: "Unsupported kind: \(String(describing: typeName))")
        }
    }
}

// MARK: - ScatterKitDesktopLevel+Response

extension ScatterKitDesktopServiceLevel {
    struct ServiceLevelResponse {
        enum Kind {
            case api(ScatterKitDesktopApiHostLevel.HostLevelResponse)
            case apiError(ScatterKitDesktopApiHostLevel.HostLevelError)
            
            enum Name: String, Encodable {
                case connected
                case rekey
                case paired
                case pair
                case api
                case diconnect
            }
        }
        
        let request: ScatterKitDesktopServiceLevel.ServiceLevelRequest
        let header: ScatterKitDesktopServiceLevel.Header
        let name: Kind.Name
        let kind: Kind?
    }
}

extension ScatterKitDesktopServiceLevel.ServiceLevelResponse: Encodable {
    enum CodingKeys: String, CodingKey {
        case header
        case data
    }
    
    func encode(to encoder: Encoder) throws {
        switch kind {
        case .api(let api)?:
            var container = encoder.singleValueContainer()
            try container.encode(api)
        case .apiError(let apiError)?:
            var container = encoder.singleValueContainer()
            try container.encode(apiError)
        case nil:
            _ = encoder.unkeyedContainer()
        }
    }
}
