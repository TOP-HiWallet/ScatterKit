//
//  Decodable+Extension.swift
//  ScatterKit
//
//  Created by Alex Melnichuk on 3/21/19.
//  Copyright © 2019 Baltic International Group OU. All rights reserved.
//

import Foundation

extension KeyedDecodingContainer {
    func decoded<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T where T : DecodingConvertible {
        return try type.decoded(self, forKey: key)
    }
}

protocol DecodingConvertible {
    static func decoded<K>(_ container: KeyedDecodingContainer<K>, forKey key: KeyedDecodingContainer<K>.Key) throws -> Self
}

extension UInt8: DecodingConvertible {}
extension UInt16: DecodingConvertible {}
extension UInt32: DecodingConvertible {}

extension FixedWidthInteger where Self: Decodable & DecodingConvertible {
    static func decoded<K>(_ container: KeyedDecodingContainer<K>, forKey key: K) throws -> Self where K : CodingKey {
        do {
            return try container.decode(Self.self, forKey: key)
        } catch {
            let string = try container.decode(String.self, forKey: key).trimmingCharacters(in: .whitespacesAndNewlines)
            guard let int = Self(string) else {
                throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "Unable to parse \(Self.self) type from string for key: \(key)")
            }
            return int
        }
    }
}

extension Date: DecodingConvertible {
    static func decoded<K>(_ container: KeyedDecodingContainer<K>, forKey key: K) throws -> Date where K : CodingKey {
        if let dateString = try? container.decode(String.self, forKey: key) {
            let dateFormatter = DateFormatter()
            let dateFormat = dateString.contains(".")
                ? "yyyy-MM-dd'T'HH:mm:ss.SSS"
                : "yyyy-MM-dd'T'HH:mm:ss"
            dateFormatter.dateFormat = dateFormat
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
        }
        if let date = try? container.decode(Date.self, forKey: key) {
            return date
        }
        if let timestamp = try? container.decode(UInt64.self, forKey: key) {
            return Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000 )
        }
        let errorMessage = "Unable to parse \(Date.self) for key: \(key)"
        throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: errorMessage)
    }
}
