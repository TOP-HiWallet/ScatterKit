//
//  ScatterKitBrowserApiHostLevel.swift
//  scatter2
//
//  Created by Alex Melnichuk on 5/28/19.
//  Copyright © 2019 Alex Melnichuk. All rights reserved.
//

import UIKit
import WebKit

class ScatterKitBrowserApiHostLevel: ScatterKitHostLevelProtocol {
    typealias ServiceLevel = ScatterKitBrowserServiceLevel
    typealias HostLevelRequest = ScatterKit.Request
    typealias HostLevelResponse = ScatterKit.Response
    typealias HostLevelError = ScatterKit.Response
    
    weak var serviceLevel: ServiceLevel?
    private var clientLevel: ScatterKitBrowserApiClientLevel!
    
    init(serviceLevel: ServiceLevel) {
        self.serviceLevel = serviceLevel
        self.clientLevel = ScatterKitBrowserApiClientLevel(hostLevel: self)
    }
    
    func sendClientLevelRequest(_ request: HostLevelRequest, serviceRequest: ServiceLevel.ServiceLevelRequest) throws {
        try clientLevel.sendDelegateRequest(request,
                                            hostRequest: request,
                                            serviceRequest: serviceRequest)
    }
    
    func makeServiceLevelResponse(hostResponse: HostLevelResponse,
                                  hostRequest: HostLevelRequest,
                                  serviceRequest: ServiceLevel.ServiceLevelRequest) throws -> ServiceLevel.ServiceLevelResponse {
        return hostResponse
    }
    
    func makeServiceLevelError(hostError: HostLevelError,
                               hostRequest: HostLevelRequest,
                               serviceRequest: ServiceLevel.ServiceLevelRequest) throws -> ServiceLevel.ServiceLevelError {
        return hostError
    }
}
