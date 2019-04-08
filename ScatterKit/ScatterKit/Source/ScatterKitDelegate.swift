//
//  ScatterKitDelegate.swift
//  ScatterKit
//
//  Created by Alex Melnichuk on 3/9/19.
//  Copyright © 2019 Baltic International Group OU. All rights reserved.
//

import Foundation

public typealias SKCallback<T> = (ScatterKit.Result<T>) -> Void

public protocol ScatterKitDelegate: class {
    func scatter(didReceive error: Error, during lifetime: ScatterKitError.Lifetime)
    func scatterDidRequestAppInfo(_ completionHandler: @escaping SKCallback<ScatterKit.Response.AppInfo>) throws
    func scatterDidRequestWalletLanguage(_ completionHandler: @escaping SKCallback<String>) throws
    func scatterDidRequestAccountName(_ completionHandler: @escaping SKCallback<String>) throws
    func scatterDidRequestBalance(_ request: ScatterKit.Request.EOSBalance, completionHandler: @escaping SKCallback<ScatterKit.Response.EOSBalance>) throws
    func scatterDidRequestWalletWithAccount(_ completionHandler: @escaping SKCallback<ScatterKit.Response.WalletWithAccount>) throws
    func scatterDidRequestTransfer(_ transfer: ScatterKit.Request.Transfer, completionHandler: @escaping SKCallback<ScatterKit.Response.Transaction>) throws
    func scatterDidRequestTransaction(with actions: [ScatterKit.Request.Action], completionHandler: @escaping SKCallback<ScatterKit.Response.Transaction>) throws
    func scatterDidRequestTransactionSignature(_ request: ScatterKit.Request.TransactionSignature, completionHandler: @escaping SKCallback<ScatterKit.Response.TransactionSignature>) throws
    func scatterDidRequestMessageSignature(_ request: ScatterKit.Request.MessageSignature, completionHandler: @escaping SKCallback<ScatterKit.Response.MessageSignature>) throws
}

public extension ScatterKitDelegate {
    func scatter(didReceive error: Error, during lifetime: ScatterKitError.Lifetime) {}
    
    func scatterDidRequestAppInfo(_ completionHandler: @escaping SKCallback<ScatterKit.Response.AppInfo>) throws {
        throw ScatterKitError.unimplemented
    }

    func scatterDidRequestWalletLanguage(_ completionHandler: @escaping SKCallback<String>) throws {
        throw ScatterKitError.unimplemented
    }
    
    func scatterDidRequestAccountName(_ completionHandler: @escaping SKCallback<String>) throws {
        throw ScatterKitError.unimplemented
    }
    
    func scatterDidRequestBalance(_ request: ScatterKit.Request.EOSBalance, completionHandler: @escaping SKCallback<ScatterKit.Response.EOSBalance>) throws {
        throw ScatterKitError.unimplemented
    }
    
    func scatterDidRequestWalletWithAccount(_ completionHandler: @escaping SKCallback<ScatterKit.Response.WalletWithAccount>) throws {
        throw ScatterKitError.unimplemented
    }
    
    func scatterDidRequestTransfer(_ transfer: ScatterKit.Request.Transfer, completionHandler: @escaping SKCallback<ScatterKit.Response.Transaction>) throws {
        throw ScatterKitError.unimplemented
    }
    
    func scatterDidRequestTransaction(with actions: [ScatterKit.Request.Action], completionHandler: @escaping SKCallback<ScatterKit.Response.Transaction>) throws {
        throw ScatterKitError.unimplemented
    }
    
    func scatterDidRequestTransactionSignature(_ request: ScatterKit.Request.TransactionSignature, completionHandler: @escaping SKCallback<ScatterKit.Response.TransactionSignature>) throws {
        throw ScatterKitError.unimplemented
    }
    
    func scatterDidRequestMessageSignature(_ request: ScatterKit.Request.MessageSignature, completionHandler: @escaping SKCallback<ScatterKit.Response.MessageSignature>) throws {
        throw ScatterKitError.unimplemented
    }
}


