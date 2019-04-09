//
//  SignatureError.swift
//  Examples
//
//  Created by Alex Melnichuk on 4/9/19.
//  Copyright © 2019 Baltic International Group OU. All rights reserved.
//

import Foundation
import ScatterKit

struct SignatureError: Error, ScatterKitErrorConvertible {

    var scatterErrorMessage: String? {
        return "Signature failed"
    }
    
    var scatterErrorKind: ScatterKitError.Kind? {
        return .malicious
    }
    
    var scatterErrorCode: ScatterKitError.Code? {
        return .forbidden
    }
}
