//
//  ScatterKitServiceLevelProtocol.swift
//  scatter2
//
//  Created by Alex Melnichuk on 5/28/19.
//  Copyright © 2019 Alex Melnichuk. All rights reserved.
//

import UIKit
import WebKit

protocol ScatterKitServiceLevelProtocol: class {
    associatedtype ServiceLevelRequest
    associatedtype ServiceLevelResponse
    associatedtype ServiceLevelError
    
    var delegate: ScatterKitDelegate? { get }
    
    var queue: DispatchQueue { get }
    var delegateQueue: DispatchQueue { get }
    
    var scriptDelegate: ScatterKitScriptMessageHandlerProxy! { get }
    var webView: WKWebView? { get }
    
    func hook()
    func unhook()
    func setup()
    
    func readMessageLevelRequest(_ message: String) throws -> ServiceLevelRequest
    func sendHostLevelRequest(_ request: ServiceLevelRequest) throws
    func sendMessageLevelResponse(_ response: ServiceLevelResponse) throws
    func sendMessageLevelError(_ error: ServiceLevelError) throws
}

extension ScatterKitServiceLevelProtocol {
    func handleMessage(_ message: Any) {
        #if DEBUG
        print("__SCATTER browser message: \(message)")
        #endif
        queue.async { [weak self] in
            guard let self = self,
                let string = message as? String else {
                    return
            }
            do {
                let serviceLevelRequest = try self.readMessageLevelRequest(string)
                try? self.sendHostLevelRequest(serviceLevelRequest)
            } catch {
                #if DEBUG
                print("__SCATTER error: \(error)")
                #endif
            }
        }
    }
}
