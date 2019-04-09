//
//  Crypto.swift
//  Examples
//
//  Created by Alex Melnichuk on 4/9/19.
//  Copyright © 2019 Baltic International Group OU. All rights reserved.
//

import Foundation
import ScatterKit

struct Crypto {
    
    struct Transaction {
        let signatures: [String]
    }
    
    static func sha256(_ data: Data) -> Data {
        // Your sha256 implementation
        return Data()
    }
    
    static func sign(privateKey: Data, sha256Digest data: Data) throws -> String  {
        // Your eos signature implementation
        return ""
    }
    
    static func transaction(_ request: ScatterKit.Request.TransactionSignature, privateKey: Data) throws -> Transaction {
         // Your eos transaction implementation
        return Transaction(signatures: [""])
    }
}
