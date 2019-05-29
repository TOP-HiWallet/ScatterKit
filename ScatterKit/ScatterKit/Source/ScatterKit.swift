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
    
    public struct ProtocolInfo {
        static let name = "Scatter Plugin"
        static let version = "1.0.0"
    }
    
    public struct Options: OptionSet {
        public let rawValue: Int
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        public static let simulateBrowserExtension = Options(rawValue: 1 << 0)
        public static let simulateDesktopApplication = Options(rawValue: 1 << 1)
    }
    
    public var delegate: ScatterKitDelegate? {
        get {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            return _delegate
        }
        set {
            objc_sync_enter(self)
            _delegate = newValue
            webExtensionService?.delegate = newValue
            desktopApplicationService?.delegate = newValue
            objc_sync_exit(self)
        }
    }
    
    private weak var _delegate: ScatterKitDelegate? = nil
    private var webExtensionService: ScatterKitBrowserServiceLevel?
    private var desktopApplicationService: ScatterKitDesktopServiceLevel?
    
    public init(webView: WKWebView,
                options: Options = [.simulateDesktopApplication],
                queue: DispatchQueue = DispatchQueue(label: "ScatterKit.background", attributes: .concurrent),
                delegateQueue: DispatchQueue = .main) {
        if options.contains(.simulateBrowserExtension) {
            self.webExtensionService = ScatterKitBrowserServiceLevel(webView: webView,
                                                                     queue: queue,
                                                                     delegateQueue: delegateQueue)
        }
        if options.contains(.simulateDesktopApplication) {
            self.desktopApplicationService = ScatterKitDesktopServiceLevel(webView: webView,
                                                                           queue: queue,
                                                                           delegateQueue: delegateQueue)
        }
    }
    
    deinit {
        #if DEBUG
        print("\(ScatterKit.self): 🗑 deinit \(self)")
        #endif
    }
}
