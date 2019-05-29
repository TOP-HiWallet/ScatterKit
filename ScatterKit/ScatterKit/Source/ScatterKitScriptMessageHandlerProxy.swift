//
//  ScatterKitScriptMessageHandlerProxy.swift
//  scatter2
//
//  Created by Alex Melnichuk on 5/24/19.
//  Copyright © 2019 Alex Melnichuk. All rights reserved.
//

import Foundation
import WebKit

protocol ScatterKitScriptMessageHandlerProxyDelegate: class {
    func handleScriptMessage(_ message: WKScriptMessage)
}

class ScatterKitScriptMessageHandlerProxy: NSObject, WKScriptMessageHandler {
    
    private weak var parent: ScatterKitScriptMessageHandlerProxyDelegate?
    
    init(parent: ScatterKitScriptMessageHandlerProxyDelegate) {
        self.parent = parent
    }
    
    deinit {
        #if DEBUG
        print("\(ScatterKit.self): 🗑 deinit \(self)")
        #endif
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        parent?.handleScriptMessage(message)
    }
}
