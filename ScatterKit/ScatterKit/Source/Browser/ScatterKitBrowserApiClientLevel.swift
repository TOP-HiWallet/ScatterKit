//
//  ScatterKitBrowserApiClientLevel.swift
//  scatter2
//
//  Created by Alex Melnichuk on 5/28/19.
//  Copyright © 2019 Alex Melnichuk. All rights reserved.
//

import UIKit
import WebKit

class ScatterKitBrowserApiClientLevel: ScatterKitClientLevelProtocol {
    typealias ServiceLevel = ScatterKitBrowserServiceLevel
    typealias HostLevel = ScatterKitBrowserApiHostLevel
    typealias ClientLevelRequest = ScatterKit.Request
    typealias ClientLevelResponse = ScatterKit.Response
    
    weak var hostLevel: ScatterKitBrowserApiHostLevel?
    
    init(hostLevel: HostLevel) {
        self.hostLevel = hostLevel
    }
    
    func sendDelegateRequest(_ request: ClientLevelRequest, hostRequest: HostLevel.HostLevelRequest, serviceRequest: ServiceLevel.ServiceLevelRequest) throws {
        try sendApiClientLevelRequest(request: request,
                                      hostRequest: hostRequest,
                                      serviceRequest: serviceRequest)
    }
    
    func makeHostLevelResponse(clientResponse: ClientLevelResponse, hostRequest: HostLevel.HostLevelRequest) throws -> HostLevel.HostLevelResponse {
        return clientResponse
    }
    
    func makeHostLevelError(clientError: Error,
                            clientRequest: ClientLevelRequest,
                            hostRequest: HostLevel.HostLevelRequest,
                            serviceRequest: ServiceLevel.ServiceLevelRequest) throws -> HostLevel.HostLevelError {
        return ScatterKit.Response(request: clientRequest,
                                   code: .error,
                                   data: .error(clientError),
                                   message: clientError.localizedDescription)
       
    }
}
