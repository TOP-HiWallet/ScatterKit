//
//  ScatterKitResponse.swift
//  ScatterKit
//
//  Created by Alex Melnichuk on 3/18/19.
//  Copyright © 2019 Baltic International Group OU. All rights reserved.
//

import Foundation

extension ScatterKit {
    public struct Response: Encodable {
        enum Params {
            case appInfo(AppInfo)
            case walletLanguage(language: String)
            case eosAccount(name: String)
            case eosBalance(EOSBalance)
            case walletWithAccount(WalletWithAccount)
            case pushActions(Transaction)
            case pushTransfer(Transaction)
            case transactionSignature(TransactionSignature)
            case messageSignature(MessageSignature)
            case error(Error)
        }
        
        enum CodingKeys: String, CodingKey {
            case data
            case message
            case code
            // error only
            case isError
            case type
        }
        
        enum Code: Int, Encodable {
            case success = 0
            case error = 1
        }
        
        let request: Request
        let code: Code
        let data: Params
        let message: String
      
        //let serialNumber: String
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            if case let .error(error) = data {
                let scatterError = error as? ScatterKitErrorConvertible
                let errorMessage = scatterError?.scatterErrorMessage ?? message
                let errorCode = scatterError?.scatterErrorCode?.rawValue ?? code.rawValue
                
                try container.encode(errorCode, forKey: .code)
                try container.encode(errorMessage, forKey: .message)
                try container.encode(true, forKey: .isError)
                if let type = scatterError?.scatterErrorKind {
                    try container.encode(type, forKey: .type)
                }
                return
            }
            try container.encode(code, forKey: .code)
            try container.encode(message, forKey: .message)
            switch data {
            case .appInfo(let appInfo):
                let appInfoData = AppInfoData(appInfo: appInfo,
                                              protocolName: ProtocolInfo.name,
                                              protocolVersion: ProtocolInfo.version)
                try container.encode(appInfoData, forKey: .data)
            case .walletLanguage(let language):
                try container.encode(language, forKey: .data)
            case .eosAccount(let name):
                try container.encode(name, forKey: .data)
            case .eosBalance(let balance):
                try container.encode(balance, forKey: .data)
            case .walletWithAccount(let walletWithAccount):
                try container.encode(walletWithAccount, forKey: .data)
            case .pushActions(let transaction),
                 .pushTransfer(let transaction):
                let transactionData = TransactionData(transaction: transaction,
                                                      serialNumber: UUID().uuidString)
                try container.encode(transactionData, forKey: .data)
            case .transactionSignature(let signatureData):
                let signature = TransactionSignatureData(signData: signatureData,
                                                         serialNumber: UUID().uuidString)
                try container.encode(signature, forKey: .data)
            case .messageSignature(let messageSignature):
                try container.encode(messageSignature, forKey: .data)
            case .error:
                break
            }
        }
    }
}

extension ScatterKit.Response {
    
    // MARK: App info
    
    public struct AppInfo {
        public let app: String
        public let appVersion: String
        
        public init(app: String, appVersion: String) {
            self.app = app
            self.appVersion = appVersion
        }
    }
    
    struct AppInfoData {
        let appInfo: AppInfo
        let protocolName: String
        let protocolVersion: String
    }
    
    // MARK: Wallet with account
    
    public struct WalletWithAccount {
        public let account: String
        public let uid: String
        public let walletName: String
        public let image: String?
        
        public init(account: String, uid: String, walletName: String, image: String?) {
            self.account = account
            self.walletName = walletName
            self.uid = uid
            self.image = image
        }
    }
    
    // MARK: EOS balance
    
    public struct EOSBalance: Encodable {

        public let balance: String
        public let contract: String
        public let account: String
        
        public init(balance: String, contract: String, account: String) {
            self.balance = balance
            self.contract = contract
            self.account = account
        }
        
        public init(balance: Decimal, symbol: String, contract: String, account: String) {
            let balanceString = "\(balance) \(symbol)"
            self.init(balance: balanceString, contract: contract, account: account)
        }
    }
    
    // MARK: Transfer and actions
    
    public struct Transaction {
        let txId: String
        let blockNum: String
    }
    
    struct TransactionData {
        let transaction: Transaction
        let serialNumber: String
    }
    
    // MARK: Transaction signature
    
    public struct TransactionSignature {
        public let signatures: [String]
        public let returnedFields: [String: Any]
        
        public init(signatures: [String], returnedFields: [String: Any]) {
            self.signatures = signatures
            self.returnedFields = returnedFields
        }
    }
    
    struct TransactionSignatureData: Encodable {
        let signData: TransactionSignature
        let serialNumber: String
    }
    
    // MARK: Message signature
    
    public struct MessageSignature: Encodable {
        let message: String
        let data: String
        
        public init(message: String, signature: String) {
            self.message = message
            self.data = signature
        }
    }
}

// MARK: AppInfoData+Encodable

extension ScatterKit.Response.AppInfoData: Encodable {
    enum CodingKeys: String, CodingKey {
        case app = "app"
        case appVersion = "app_version"
        case protocolName = "protocol_name"
        case protocolVersion = "protocol_version"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(appInfo.app, forKey: .app)
        try container.encode(appInfo.appVersion, forKey: .appVersion)
        try container.encode(protocolName, forKey: .protocolName)
        try container.encode(protocolVersion, forKey: .protocolVersion)
    }
}

// MARK: WalletWithAccount+Encodable

extension ScatterKit.Response.WalletWithAccount: Encodable {
    enum CodingKeys: String, CodingKey {
        case account = "account"
        case uid = "uid"
        case walletName = "wallet_name"
        case image = "image"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(account, forKey: .account)
        try container.encode(uid, forKey: .uid)
        try container.encode(walletName, forKey: .walletName)
        try container.encode(image ?? "", forKey: .image)
    }
}

// MARK: TransactionSignature+Encodable

extension ScatterKit.Response.TransactionSignature: Encodable {
    enum CodingKeys: String, CodingKey {
        case signatures
        case returnedFields
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(signatures, forKey: .signatures)
        try container.encode([String: String](), forKey: .returnedFields)
    }
}

// MARK: TransactionData+Encodable

extension ScatterKit.Response.TransactionData: Encodable {
    enum CodingKeys: String, CodingKey {
        case txId = "txid"
        case blockNum = "block_num"
        case serialNumber = "serialNumber"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(transaction.txId, forKey: .txId)
        try container.encode(transaction.blockNum, forKey: .blockNum)
        try container.encode(serialNumber, forKey: .serialNumber)
    }
}

