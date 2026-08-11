//
//  AuthJSONValue.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 06/08/2026.
//

import Foundation

/// Sendable JSON / form field value for ``AuthRequest`` bodies (replaces `[String: Any]`).
enum AuthJSONValue: Sendable, Equatable {
    case string(String)
    case bool(Bool)
    case int(Int)

    var jsonObject: Any {
        switch self {
        case .string(let value): return value
        case .bool(let value): return value
        case .int(let value): return value
        }
    }

    var formString: String {
        switch self {
        case .string(let value): return value
        case .bool(let value): return value ? "true" : "false"
        case .int(let value): return String(value)
        }
    }
}

typealias AuthJSONObject = [String: AuthJSONValue]

extension AuthJSONObject {
    func asJSONObject() -> [String: Any] {
        mapValues(\.jsonObject)
    }

    func encodedJSON() throws -> Data {
        try JSONSerialization.data(withJSONObject: asJSONObject())
    }

    func encodedFormURL() -> Data {
        let encoded = map { key, value in
            "\(key.urlQueryEncoded)=\(value.formString.urlQueryEncoded)"
        }
        .joined(separator: "&")
        return Data(encoded.utf8)
    }
}

extension AuthJSONObject {
    static func strings(_ values: [String: String]) -> AuthJSONObject {
        values.mapValues { .string($0) }
    }
}
