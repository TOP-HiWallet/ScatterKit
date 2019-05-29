//
//  ScatterKitScriptMessageHandlerLeakAvoider.swift
//  scatter2
//
//  Created by Alex Melnichuk on 5/24/19.
//  Copyright © 2019 Alex Melnichuk. All rights reserved.
//

import Foundation
import WebKit

class ScatterKitScriptMessageHandlerLeakAvoider: NSObject, WKScriptMessageHandler {
    
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
