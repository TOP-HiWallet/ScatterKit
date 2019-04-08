//
//  ScatterKitResult.swift
//  ScatterKit
//
//  Created by Alex Melnichuk on 3/18/19.
//  Copyright © 2019 Baltic International Group OU. All rights reserved.
//

import Foundation

public extension ScatterKit {
    enum Result<SuccessType> {
        case success(SuccessType)
        case error(Error)
    }
}
