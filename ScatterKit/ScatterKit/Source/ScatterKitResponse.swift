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
            case messageSignature(String)
            case identityFromPermissions(Identity)
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
        
        func encodeData<K>(container: inout KeyedEncodingContainer<K>, forKey key: K) throws {
            switch data {
            case .appInfo(let appInfo):
                let appInfoData = AppInfoData(appInfo: appInfo,
                                              protocolName: ProtocolInfo.name,
                                              protocolVersion: ProtocolInfo.version)
                
                try container.encode(appInfoData, forKey: key)
            case .walletLanguage(let language):
                try container.encode(language, forKey: key)
            case .eosAccount(let name):
                try container.encode(name, forKey: key)
            case .eosBalance(let balance):
                try container.encode(balance, forKey: key)
            case .walletWithAccount(let walletWithAccount):
                try container.encode(walletWithAccount, forKey: key)
            case .pushActions(let transaction),
                 .pushTransfer(let transaction):
                let transactionData = TransactionData(transaction: transaction,
                                                      serialNumber: UUID().uuidString)
                try container.encode(transactionData, forKey: key)
            case .transactionSignature(let signatureData):
                try container.encode(signatureData, forKey: key)
            case .messageSignature(let messageSignature):
                try container.encode(messageSignature, forKey: key)
            case .identityFromPermissions(let identity):
                try container.encode(identity, forKey: key)
            case .error:
                break
            }
        }
        
        func encodeError<K>(_ error: Error,
                            container: inout KeyedEncodingContainer<K>,
                            codeKey: K,
                            messageKey: K,
                            isErrorKey: K,
                            typeKey: K) throws {
            let scatterError = error as? ScatterKitErrorConvertible
            let errorMessage = scatterError?.scatterErrorMessage ?? message
            let errorCode = scatterError?.scatterErrorCode?.rawValue ?? code.rawValue
            
            try container.encode(errorCode, forKey: codeKey)
            try container.encode(errorMessage, forKey: messageKey)
            try container.encode(true, forKey: isErrorKey)
            
            if let type = scatterError?.scatterErrorKind {
                try container.encode(type, forKey: typeKey)
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            if case let .error(error) = data {
                try encodeError(error, container: &container,
                                codeKey: .code,
                                messageKey: .message,
                                isErrorKey: .isError,
                                typeKey: .type)
                return
            }
            try container.encode(code, forKey: .code)
            try container.encode(message, forKey: .message)
            try encodeData(container: &container, forKey: .data)
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
    
    public struct Identity: Encodable {
        public struct Account: Encodable {
            public enum Blockchain: String, Encodable {
                case eos
            }
            
            let name: String
            let authority: String
            let publicKey: String
            let blockchain: Blockchain
            let isHardware: Bool
            
            public init(name: String,
                        authority: String,
                        publicKey: String,
                        blockchain: Blockchain,
                        isHardware: Bool) {
                self.name = name
                self.authority = authority
                self.publicKey = publicKey
                self.blockchain = blockchain
                self.isHardware = isHardware
            }
        }
        
        let hash: String
        let publicKey: String
        let name: String
        let kyc: Bool
        let accounts: [Account]
        
        public init(hash: String,
                    publicKey: String,
                    name: String,
                    kyc: Bool,
                    accounts: [Account]) {
            self.hash = hash
            self.publicKey = publicKey
            self.name = name
            self.kyc = kyc
            self.accounts = accounts
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

