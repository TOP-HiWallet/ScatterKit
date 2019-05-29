//
//  ScatterKitClientLevelProtocol.swift
//  scatter2
//
//  Created by Alex Melnichuk on 5/28/19.
//  Copyright © 2019 Alex Melnichuk. All rights reserved.
//

import UIKit
import WebKit

protocol ScatterKitClientLevelProtocol: class where HostLevel.ServiceLevel == ServiceLevel {
    associatedtype ServiceLevel
    associatedtype HostLevel: ScatterKitHostLevelProtocol
    associatedtype ClientLevelRequest
    associatedtype ClientLevelResponse
    
    var hostLevel: HostLevel? { get }
    
    func sendDelegateRequest(_ clientRequest: ClientLevelRequest,
                             hostRequest: HostLevel.HostLevelRequest,
                             serviceRequest: ServiceLevel.ServiceLevelRequest) throws
    
    func makeHostLevelResponse(clientResponse: ClientLevelResponse,
                               hostRequest: HostLevel.HostLevelRequest) throws -> HostLevel.HostLevelResponse
    
    func makeHostLevelError(clientError: Error,
                            clientRequest: ClientLevelRequest,
                            hostRequest: HostLevel.HostLevelRequest,
                            serviceRequest: ServiceLevel.ServiceLevelRequest) throws -> HostLevel.HostLevelError
}

extension ScatterKitClientLevelProtocol {
    
    var serviceLevel: ServiceLevel? {
        return hostLevel?.serviceLevel
    }
    
    func sendServiceLevelResponse(_ clientResponse: ClientLevelResponse,
                                  hostRequest: HostLevel.HostLevelRequest,
                                  serviceRequest: ServiceLevel.ServiceLevelRequest) throws {
        guard let hostLevel = self.hostLevel,
            let serviceLevel = self.serviceLevel else {
                return
        }
        let hostLevelResponse = try makeHostLevelResponse(clientResponse: clientResponse, hostRequest: hostRequest)
        let serviceLevelResponse = try hostLevel.makeServiceLevelResponse(hostResponse: hostLevelResponse, hostRequest: hostRequest, serviceRequest: serviceRequest)
        try serviceLevel.sendMessageLevelResponse(serviceLevelResponse)
    }
    
    func sendServiceLevelError(_ error: Error,
                               clientRequest: ClientLevelRequest,
                               hostRequest: HostLevel.HostLevelRequest,
                               serviceRequest: ServiceLevel.ServiceLevelRequest) throws {
        guard let hostLevel = self.hostLevel,
            let serviceLevel = self.serviceLevel else {
                return
        }
        let hostLevelError = try makeHostLevelError(clientError: error,
                                                    clientRequest: clientRequest,
                                                    hostRequest: hostRequest,
                                                    serviceRequest: serviceRequest)
        let serviceLevelError = try hostLevel.makeServiceLevelError(hostError: hostLevelError,
                                                                    hostRequest: hostRequest,
                                                                    serviceRequest: serviceRequest)
        try serviceLevel.sendMessageLevelError(serviceLevelError)
    }
    
    func asyncCallDelegate(_ clientRequest: ClientLevelRequest,
                           hostRequest: HostLevel.HostLevelRequest,
                           serviceRequest: ServiceLevel.ServiceLevelRequest,
                           delegateCallback: @escaping (ScatterKitDelegate) throws -> Void) {
        weak var delegate = serviceLevel?.delegate
        serviceLevel?.delegateQueue.async { [weak self, weak delegate] in
            do {
                // send callback to delegate
                if let delegate = delegate {
                    try delegateCallback(delegate)
                }
            } catch {
                // client thrown error, handle error
                guard let self = self else { return }
                let error = ScatterKitError.result(error)
                try? self.sendServiceLevelError(error,
                                                clientRequest: clientRequest,
                                                hostRequest: hostRequest,
                                                serviceRequest: serviceRequest)
            }
        }
    }
    
    func makeResultCallback<T>(clientRequest: ClientLevelRequest,
                               hostRequest: HostLevel.HostLevelRequest,
                               serviceRequest: ServiceLevel.ServiceLevelRequest,
                               parseResponse: @escaping (T) throws -> ClientLevelResponse) -> SKCallback<T> {
        return { [weak self] result in
            self?.serviceLevel?.queue.async { [weak self] in
                guard let self = self else { return }
                switch result {
                case .success(let success):
                    let response: ClientLevelResponse
                    do {
                        response = try parseResponse(success)
                    } catch {
                        let errorMessage = "Error when transforming response for request \(clientRequest)"
                        let error = ScatterKitError.parse(message: errorMessage)
                        try? self.sendServiceLevelError(error,
                                                        clientRequest: clientRequest,
                                                        hostRequest: hostRequest,
                                                        serviceRequest: serviceRequest)
                        return
                    }
                    
                    do {
                        try self.sendServiceLevelResponse(response, hostRequest: hostRequest, serviceRequest: serviceRequest)
                    } catch {
                        try? self.sendServiceLevelError(error,
                                                        clientRequest: clientRequest,
                                                        hostRequest: hostRequest,
                                                        serviceRequest: serviceRequest)
                    }
                case .error(let error):
                    try? self.sendServiceLevelError(error,
                                                    clientRequest: clientRequest,
                                                    hostRequest: hostRequest,
                                                    serviceRequest: serviceRequest)
                }
            }
        }
    }
}
