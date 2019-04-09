//
//  ScatterKitError.swift
//  ScatterKit
//
//  Created by Alex Melnichuk on 3/18/19.
//  Copyright © 2019 Baltic International Group OU. All rights reserved.
//

import Foundation

public protocol ScatterKitErrorConvertible {
    var scatterErrorMessage: String? { get }
    var scatterErrorKind: ScatterKitError.Kind? { get }
    var scatterErrorCode: ScatterKitError.Code? { get }
}

public enum ScatterKitError: Swift.Error {
    
    case unimplemented
    case timeout
    case parse(message: String)
    case result(Error)
    
    public enum Lifetime {
        case request
        case response
        case callback
        case javascriptEvaluation
    }
    
    public enum Kind: String, Encodable {
        case malicious
        case locked
        case promptClosed = "prompt_closed"
        case upgradeRequired = "upgrade_required"
        case signatureRejected = "signature_rejected"
        case identityMissing = "identity_missing"
        case accountMissing = "account_missing"
        case malformedRequirements = "malformed_requirements"
        case noNetwork = "no_network"
    }
    
    public enum Code: Int, Encodable {
        case noSignature = 402
        case forbidden = 403
        case timedOut = 408
        case locked = 423
        case upgradeRequired = 426
        case tooManyRequests = 429
    }
}

