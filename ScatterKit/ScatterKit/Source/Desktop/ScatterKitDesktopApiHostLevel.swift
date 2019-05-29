//
//  ScatterKitDesktopApiHostLevel.swift
//  scatter2
//
//  Created by Alex Melnichuk on 5/27/19.
//  Copyright © 2019 Alex Melnichuk. All rights reserved.
//

import UIKit
import WebKit

class ScatterKitDesktopApiHostLevel: ScatterKitHostLevelProtocol {

    typealias ServiceLevel = ScatterKitDesktopServiceLevel
    
    weak var serviceLevel: ServiceLevel?
    private var clientLevel: ScatterKitDesktopApiClientLevel!
    
    init(serviceLevel: ServiceLevel) {
        self.serviceLevel = serviceLevel
        self.clientLevel = ScatterKitDesktopApiClientLevel(hostLevel: self)
    }
    
    func sendClientLevelRequest(_ request: HostLevelRequest, serviceRequest: ServiceLevel.ServiceLevelRequest) throws {
        try clientLevel.sendDelegateRequest(request.data,
                                            hostRequest: request,
                                            serviceRequest: serviceRequest)
    }
    
    func makeServiceLevelResponse(hostResponse: HostLevelResponse,
                                  hostRequest: HostLevelRequest,
                                  serviceRequest: ServiceLevel.ServiceLevelRequest) throws -> ServiceLevel.ServiceLevelResponse {
        return ServiceLevel.ServiceLevelResponse(request: serviceRequest,
                                                 header: serviceRequest.header,
                                                 name: .api,
                                                 kind: .api(hostResponse))
    }
    
    func makeServiceLevelError(hostError: HostLevelError,
                               hostRequest: HostLevelRequest,
                               serviceRequest: ServiceLevel.ServiceLevelRequest) throws -> ServiceLevel.ServiceLevelError {
        return ServiceLevel.ServiceLevelError(request: serviceRequest,
                                              header: serviceRequest.header,
                                              name: .api,
                                              kind: .apiError(hostError))
    }
}


// MARK: ScatterKitDesktopApiHostLevel+HostLevelRequest

extension ScatterKitDesktopApiHostLevel {
    struct HostLevelRequest {
        var data: ScatterKit.Request
        var id: String
        var appKey: String
        var nonce: String
        var nextNonce: String
        var plugin: String?
    }
}

extension ScatterKitDesktopApiHostLevel.HostLevelRequest: Decodable {
    enum DataCodingKeys: String, CodingKey {
        case data
        case plugin
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case appkey
        case nonce
        case nextNonce
        case payload
        case type
    }
    
    init(from decoder: Decoder) throws {
        let dataContainer = try decoder.container(keyedBy: DataCodingKeys.self)
        self.plugin = try dataContainer.decodeIfPresent(String.self, forKey: .plugin)
        
        let container = try dataContainer.nestedContainer(keyedBy: CodingKeys.self, forKey: .data) //try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.appKey = try container.decode(String.self, forKey: .appkey)
        do {
            self.nonce = try container.decode(String.self, forKey: .nonce)
        } catch {
            let nonce = try container.decode(Int.self, forKey: .nonce)
            self.nonce = "\(nonce)"
        }
        
        do {
            self.nextNonce = try container.decode(String.self, forKey: .nextNonce)
        } catch {
            let nextNonce = try container.decode(Int.self, forKey: .nextNonce)
            self.nextNonce = "\(nextNonce)"
        }
        
        let methodName = try container.decode(ScatterKit.Request.MethodName.self, forKey: .type)
        self.data = try ScatterKit.Request(container: container, forKey: .payload, methodName: methodName, callback: "")
        print("__SCATTER_KIT request: \(data)")
    }
}

// MARK: ScatterKitDesktopApiHostLevel+HostLevelResponse

extension ScatterKitDesktopApiHostLevel {
    struct HostLevelResponse {
        var request: ScatterKitDesktopApiHostLevel.HostLevelRequest
        var response: ScatterKit.Response
    }
}

extension ScatterKitDesktopApiHostLevel.HostLevelResponse: Encodable {
    enum ResultCodingKeys: String, CodingKey {
        case id
        case result
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ScatterKitDesktopServiceLevel.ServiceLevelResponse.Kind.Name.api)
        
        var resultContainer = container.nestedContainer(keyedBy: ResultCodingKeys.self)
        try resultContainer.encode(request.id, forKey: .id)
        try response.encodeData(container: &resultContainer, forKey: .result)
    }
}


// MARK: ScatterKitDesktopApiHostLevel+HostLevelError

extension ScatterKitDesktopApiHostLevel {
    struct HostLevelError {
        var request: ScatterKitDesktopApiHostLevel.HostLevelRequest
        var response: ScatterKit.Response
        var error: Error
    }
}

extension ScatterKitDesktopApiHostLevel.HostLevelError: Encodable {
    typealias ResultCodingKeys = ScatterKitDesktopApiHostLevel.HostLevelResponse.ResultCodingKeys
    
    enum ErrorCodingKeys: String, CodingKey {
        case code
        case message
        case isError
        case type
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ScatterKitDesktopServiceLevel.ServiceLevelResponse.Kind.Name.api)
        
        var resultContainer = container.nestedContainer(keyedBy: ResultCodingKeys.self)
        try resultContainer.encode(request.id, forKey: .id)
        
        var errorContainer = resultContainer.nestedContainer(keyedBy: ErrorCodingKeys.self, forKey: .result)
        try response.encodeError(error,
                                 container: &errorContainer,
                                 codeKey: .code,
                                 messageKey: .message,
                                 isErrorKey: .isError,
                                 typeKey: .type)
        
      
    }
}

