//
//  ScatterKitRequest.swift
//  ScatterKit
//
//  Created by Alex Melnichuk on 3/18/19.
//  Copyright © 2019 Baltic International Group OU. All rights reserved.
//

import Foundation

extension ScatterKit {
    
    public struct Request {
        enum Params {
            case appInfo
            case walletLanguage
            case eosBalance(EOSBalance)
            case walletWithAccount
            case pushActions([Action])
            case pushTransfer(Transfer)
            case transactionSignature(TransactionSignatureKind)
            case messageSignature(MessageSignature)
            case identityFromPermissions
        }
        
        enum MethodName: String, Codable {
            case getAppInfo
            case walletLanguage
            case getEosBalance
            case getWalletWithAccount
            case requestSignature
            case authenticate
            case getArbitrarySignature
            case requestArbitrarySignature
            case pushTransfer
            case pushActions
            case identityFromPermissions
            case getOrRequestIdentity
            case unknown
        }
        
        let methodName: MethodName
        let params: Params?
        let callback: String
    }
}

extension ScatterKit.Request: Decodable {
    enum CodingKeys: String, CodingKey {
        case methodName
        case params
        case callback
    }
    
    init<K>(container: KeyedDecodingContainer<K>,
            forKey key: K,
            methodName: MethodName,
            callback: String) throws {
        self.methodName = methodName
        self.callback = callback
        do {
            switch methodName {
            case .getAppInfo:
                self.params = .appInfo
            case .walletLanguage:
                self.params = .walletLanguage
            case .getEosBalance:
                let eosBalance = try container.decode(EOSBalance.self, forKey: key)
                self.params = .eosBalance(eosBalance)
            case .getWalletWithAccount:
                self.params = .walletWithAccount
            case .pushActions:
                let paramsString = (try? container.decode(String.self, forKey: key)) ?? ""
                let data = Data(paramsString.utf8)
                let actions = try [Action](actionsData: data)
                self.params = .pushActions(actions)
            case .pushTransfer:
                let transfer = try container.decode(Transfer.self, forKey: key)
                self.params = .pushTransfer(transfer)
            case .requestSignature:
                do {
                    let signatureRequest = try container.decode(TransactionSignature.self, forKey: key)
                    self.params = .transactionSignature(.transaction(signatureRequest))
                } catch {
                    let signatureRequest = try container.decode(SerializedTransactionSignature.self, forKey: key)
                    self.params = .transactionSignature(.serializedTransaction(signatureRequest))
                }
            case .getArbitrarySignature,
                 .requestArbitrarySignature,
                 .authenticate:
                let messageSignature = try container.decode(MessageSignature.self, forKey: key)
                self.params = .messageSignature(messageSignature)
            case .unknown:
                self.params = nil
            case .getOrRequestIdentity, .identityFromPermissions:
                self.params = .identityFromPermissions
            }
        } catch {
            self.params = nil
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let methodName = (try? container.decode(MethodName.self, forKey: .methodName)) ?? .unknown
        let callback = try container.decode(String.self, forKey: .callback)
        try self.init(container: container,
                      forKey: .params,
                      methodName: methodName,
                      callback: callback)
    }
}

extension ScatterKit.Request {
  
    // MARK: Get EOS balance
    
    public struct EOSBalance: Decodable {
        public let account: String
        public let contract: String
    }
    
    // MARK: Transfer
    
    public struct Transfer {
        public let from: String
        public let to: String
        public let amount: Decimal
        public let symbol: String
        public let memo: String?
        public let contract: String
    }
    
    public struct Action {
        public let account: String
        public let name: String
        public let data: [String: Any]
    }
    
    public enum TransactionSignatureKind {
        case transaction(TransactionSignature)
        case serializedTransaction(SerializedTransactionSignature)
    }
    
    // MARK: Transaction Signature
    
    public struct TransactionSignature: Decodable {
        public struct Buffer {
            public enum Kind: String, Decodable {
                case buffer = "Buffer"
            }
            
            public let type: Kind
            public let data: Data
        }
        
        public let transaction: ScatterKit.Transaction
        public let buf: Buffer
    }
    
    // MARK: Serialized transaction signature

    public struct SerializedTransactionSignature: Decodable {
        public struct Transaction: Decodable {
            public let chainId: String
            public let serializedTransaction: String
        }
        public let transaction: Transaction
    }
    
    // MARK: Message signature
    
    public struct MessageSignature: Decodable {
        public let publicKey: String
        public let data: String
        public let whatFor: String?
        public let isHash: Bool
    }
}

extension Array where Element == ScatterKit.Request.Action {
    init(actionsData: Data) throws {
        let object = try JSONSerialization.jsonObject(with: actionsData, options: [.allowFragments])
        guard let dictionary = object as? [String: Any],
            let actions = dictionary["actions"] as? [[String: Any]] else {
                throw ScatterKitError.parse(message: "Unable to decode actions array for \(ScatterKit.Request.Action.self)")
        }
        self = try actions.map { action in
            guard let account = action["account"] as? String,
                let name = action["name"] as? String else {
                throw ScatterKitError.parse(message: "Unable to decode \(ScatterKit.Request.Action.self)")
            }
            let data = action["data"] as? [String: Any] ?? [:]
            return ScatterKit.Request.Action(account: account, name: name, data: data)
        }
    }
}

// MARK: Transfer+Decodable

extension ScatterKit.Request.Transfer: Decodable {
    enum CodingKeys: String, CodingKey {
        case from
        case to
        case quantity
        case memo
        case contract
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let quantity = try container.decode(String.self, forKey: .quantity)
        let quantityParts = quantity.split(separator: " ")
        guard quantityParts.count >= 2 else {
            throw DecodingError.dataCorruptedError(forKey: .quantity, in: container, debugDescription: "Invalid quantity format: \(quantity)")
        }
        guard let amount = Decimal(string: String(quantityParts[0]), locale: Locale(identifier: "en_US")) else {
            throw DecodingError.dataCorruptedError(forKey: .quantity, in: container, debugDescription: "Invalid amount format: \(quantity)")
        }
        let symbol = String(quantityParts[1])
        guard !symbol.isEmpty else {
            throw DecodingError.dataCorruptedError(forKey: .quantity, in: container, debugDescription: "Invalid symbol format: \(quantity)")
        }
        self.from = try container.decode(String.self, forKey: .from)
        self.to = try container.decode(String.self, forKey: .to)
        self.amount = amount
        self.symbol = symbol
        self.memo = try container.decodeIfPresent(String.self, forKey: .memo)
        self.contract = try container.decode(String.self, forKey: .to)
    }
}

// MARK: TransactionSignature.Buffer+Decodable

extension ScatterKit.Request.TransactionSignature.Buffer: Decodable {
    enum CodingKeys: String, CodingKey {
        case type
        case data
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let bytes = try container.decode([UInt8].self, forKey: .data)
        self.type = try container.decode(Kind.self, forKey: .type)
        self.data = Data(bytes)
    }
}

