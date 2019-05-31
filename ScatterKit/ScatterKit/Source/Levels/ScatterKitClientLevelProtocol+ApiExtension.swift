//
//  ScatterKitClientLevelProtocol+ApiExtension.swift
//  scatter2
//
//  Created by Alex Melnichuk on 5/28/19.
//  Copyright © 2019 Alex Melnichuk. All rights reserved.
//

import Foundation

extension ScatterKitClientLevelProtocol where
    ClientLevelRequest == ScatterKit.Request,
    ClientLevelResponse == ScatterKit.Response {
    
    func sendApiClientLevelRequest(request: ClientLevelRequest,
                                   hostRequest: HostLevel.HostLevelRequest,
                                   serviceRequest: ServiceLevel.ServiceLevelRequest) throws {
        typealias Request = ClientLevelRequest
        typealias Response = ClientLevelResponse
        
        guard let params = request.params else {
            let errorMessage = "Unable to parse model for \(request.methodName)"
            let parseError = ScatterKitError.parse(message: errorMessage)
            try? self.sendServiceLevelError(parseError,
                                            clientRequest: request,
                                            hostRequest: hostRequest,
                                            serviceRequest: serviceRequest)
            return
        }
        
        switch params {
        case .appInfo:
            let callback: SKCallback<Response.AppInfo> = self.makeResultCallback(
                clientRequest: request,
                hostRequest: hostRequest,
                serviceRequest: serviceRequest) {
                    Response(request: request, code: .success, data: .appInfo($0), message: "success")
            }
            self.asyncCallDelegate(request,
                                   hostRequest: hostRequest,
                                   serviceRequest: serviceRequest) { delegate in
                try delegate.scatterDidRequestAppInfo(callback)
            }
        case .walletLanguage:
            let callback: SKCallback<String> = self.makeResultCallback(
                clientRequest: request,
                hostRequest: hostRequest,
                serviceRequest: serviceRequest) {
                    Response(request: request, code: .success, data: .walletLanguage(language: $0), message: "success")
            }
            self.asyncCallDelegate(request,
                                   hostRequest: hostRequest,
                                   serviceRequest: serviceRequest) { delegate in
                try delegate.scatterDidRequestWalletLanguage(callback)
            }
        case .eosBalance(let balance):
            let callback: SKCallback<Response.EOSBalance> = self.makeResultCallback(
                clientRequest: request,
                hostRequest: hostRequest,
                serviceRequest: serviceRequest) {
                    Response(request: request, code: .success, data: .eosBalance($0), message: "success")
            }
            self.asyncCallDelegate(request,
                                   hostRequest: hostRequest,
                                   serviceRequest: serviceRequest) { delegate in
                try delegate.scatterDidRequestBalance(balance, completionHandler: callback)
            }
        case .walletWithAccount:
            let callback: SKCallback<Response.WalletWithAccount> = self.makeResultCallback(
                clientRequest: request,
                hostRequest: hostRequest,
                serviceRequest: serviceRequest) {
                    Response(request: request, code: .success, data: .walletWithAccount($0), message: "success")
            }
            self.asyncCallDelegate(request,
                                   hostRequest: hostRequest,
                                   serviceRequest: serviceRequest) { delegate in
                try delegate.scatterDidRequestWalletWithAccount(callback)
            }
        case .pushActions(let actions):
            let callback: SKCallback<Response.Transaction> = self.makeResultCallback(
                clientRequest: request,
                hostRequest: hostRequest,
                serviceRequest: serviceRequest) {
                    Response(request: request, code: .success, data: .pushActions($0), message: "success")
            }
            self.asyncCallDelegate(request,
                                   hostRequest: hostRequest,
                                   serviceRequest: serviceRequest) { delegate in
                try delegate.scatterDidRequestTransaction(with: actions, completionHandler: callback)
            }
        case .pushTransfer(let transfer):
            let callback: SKCallback<Response.Transaction> = self.makeResultCallback(
                clientRequest: request,
                hostRequest: hostRequest,
                serviceRequest: serviceRequest) {
                    Response(request: request, code: .success, data: .pushTransfer($0), message: "success")
            }
            self.asyncCallDelegate(request,
                                   hostRequest: hostRequest,
                                   serviceRequest: serviceRequest) { delegate in
                try delegate.scatterDidRequestTransfer(transfer, completionHandler: callback)
            }
        case .transactionSignature(let transaction):
            let callback: SKCallback<Response.TransactionSignature> = self.makeResultCallback(
                clientRequest: request,
                hostRequest: hostRequest,
                serviceRequest: serviceRequest) {
                    Response(request: request, code: .success, data: .transactionSignature($0), message: "success")
            }
            self.asyncCallDelegate(request,
                                   hostRequest: hostRequest,
                                   serviceRequest: serviceRequest) { delegate in
                try delegate.scatterDidRequestTransactionSignature(transaction, completionHandler: callback)
            }
        case .messageSignature(let message):
            let callback: SKCallback<String> = self.makeResultCallback(
                clientRequest: request,
                hostRequest: hostRequest,
                serviceRequest: serviceRequest) {
                    Response(request: request, code: .success, data: .messageSignature($0), message: "success")
            }
            self.asyncCallDelegate(request,
                                   hostRequest: hostRequest,
                                   serviceRequest: serviceRequest) { delegate in
                try delegate.scatterDidRequestMessageSignature(message, completionHandler: callback)
            }
        case .authentication(let authentication):
            let callback: SKCallback<String> = self.makeResultCallback(
                clientRequest: request,
                hostRequest: hostRequest,
                serviceRequest: serviceRequest) {
                    Response(request: request, code: .success, data: .messageSignature($0), message: "success")
            }
            self.asyncCallDelegate(request,
                                   hostRequest: hostRequest,
                                   serviceRequest: serviceRequest) { delegate in
                try delegate.scatterDidRequestAuthentication(authentication, completionHandler: callback)
            }
        case .identityFromPermissions:
            let callback: SKCallback<Response.Identity> = self.makeResultCallback(
                clientRequest: request,
                hostRequest: hostRequest,
                serviceRequest: serviceRequest) {
                    Response(request: request, code: .success, data: .identityFromPermissions($0), message: "success")
            }
            self.asyncCallDelegate(request,
                                    hostRequest: hostRequest,
                                    serviceRequest: serviceRequest) { delegate in
                try delegate.scatterDidRequestIdentity(callback)
            }
        }
    }
}
