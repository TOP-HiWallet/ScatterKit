//
//  ScatterKitHostLevelProtocol.swift
//  scatter2
//
//  Created by Alex Melnichuk on 5/28/19.
//  Copyright © 2019 Alex Melnichuk. All rights reserved.
//

import UIKit
import WebKit

protocol ScatterKitHostLevelProtocol: class {
    associatedtype ServiceLevel: ScatterKitServiceLevelProtocol
    associatedtype HostLevelRequest
    associatedtype HostLevelResponse
    associatedtype HostLevelError
    
    var serviceLevel: ServiceLevel? { get }
    
    func sendClientLevelRequest(_ hostRequest: HostLevelRequest, serviceRequest: ServiceLevel.ServiceLevelRequest) throws
    
    func makeServiceLevelResponse(hostResponse: HostLevelResponse,
                                  hostRequest: HostLevelRequest,
                                  serviceRequest: ServiceLevel.ServiceLevelRequest) throws -> ServiceLevel.ServiceLevelResponse
    
    func makeServiceLevelError(hostError: HostLevelError,
                               hostRequest: HostLevelRequest,
                               serviceRequest: ServiceLevel.ServiceLevelRequest) throws -> ServiceLevel.ServiceLevelError
}
