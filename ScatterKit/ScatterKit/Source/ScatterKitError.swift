//
//  ScatterKitError.swift
//  ScatterKit
//
//  Created by Alex Melnichuk on 3/18/19.
//  Copyright © 2019 Baltic International Group OU. All rights reserved.
//

import Foundation

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
}

