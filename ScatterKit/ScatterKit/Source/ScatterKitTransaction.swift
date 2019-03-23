//
//  ScatterKitTransaction.swift
//  ScatterKit
//
//  Created by Alex Melnichuk on 3/20/19.
//  Copyright © 2019 Baltic International Group OU. All rights reserved.
//

import Foundation

extension ScatterKit {
    public struct Transaction {
        public let refBlockNum: UInt16
        public let refBlockPrefix: UInt32
        public let maxNetUsageWords: UInt32
        public let maxCpuUsageMs: UInt8
        public let delaySec: UInt32
        public let expiration: Date
        public let actions: [Action]
        public let contextFreeActions: [Action]
    }
}

extension ScatterKit.Transaction {
    public struct Action: Decodable {
        public let account: String
        public let name: String
        public let authorization: [Authorization]
        public let data: String
    }
}

extension ScatterKit.Transaction.Action {
    public struct Authorization: Decodable {
        public let actor: String
        public let permission: String
    }
}

extension ScatterKit.Transaction: Decodable {
    enum CodingKeys: String, CodingKey {
        case refBlockNum = "ref_block_num"
        case refBlockPrefix = "ref_block_prefix"
        case maxNetUsageWords = "max_net_usage_words"
        case maxCpuUsageMs = "max_cpu_usage_ms"
        case delaySec = "delay_sec"
        case expiration = "expiration"
        case actions = "actions"
        case contextFreeActions = "context_free_actions"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let expirationDate = try container.decoded(Date.self, forKey: .expiration)
        let interval = TimeZone.current.secondsFromGMT(for: expirationDate)
        let expiration = Date(timeInterval: TimeInterval(interval), since: expirationDate)
        
        self.expiration = expiration
        self.refBlockNum = try container.decoded(UInt16.self, forKey: .refBlockNum)
        self.refBlockPrefix = try container.decoded(UInt32.self, forKey: .refBlockPrefix)
        self.maxNetUsageWords = (try? container.decoded(UInt32.self, forKey: .maxNetUsageWords)) ?? 0
        self.maxCpuUsageMs = (try? container.decoded(UInt8.self, forKey: .maxCpuUsageMs)) ?? 0
        self.delaySec = try container.decoded(UInt32.self, forKey: .delaySec)
        self.actions = try container.decode([Action].self, forKey: .actions)
        self.contextFreeActions = try container.decode([Action].self, forKey: .contextFreeActions)
    }
}


