//
//  FlowParsing.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

struct FlowMessage: Sendable, Equatable {
    let text: String
    let type: String?
    let code: Int?
    let context: [String: String]?
}

struct FlowNodeAttributes: Sendable {
    let id: String?
    let name: String?
    let value: String?
    let type: String?
}

struct ParsedFlow: Sendable {
    let id: String
    let type: String?
    let state: String?
    let active: String?
    let expiresAt: Date?
    let messages: [FlowMessage]
    let nodes: [FlowNodeAttributes]
    let formActions: [String]
    let formIds: [String]

    var flowTokenId: String? {
        nodes.first(where: { $0.id == "flowTokenId" || $0.name == "flowTokenId" })?.value
    }

    var emailHint: String? {
        nodes.first(where: { $0.id == "email" || $0.name == "email" })?.value
    }

    var mobileHint: String? {
        nodes.first(where: { $0.id == "mobile" || $0.name == "mobile" })?.value
    }

    var usernameHint: String? {
        guard let value = nodes.first(where: { $0.id == "username" || $0.name == "username" })?.value else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var pointsToVerification: Bool {
        formActions.contains { $0.contains("/verification") }
            || formIds.contains("captcha")
    }
}

enum FlowJSONParser {
    static func parse(_ data: Data) throws -> ParsedFlow {
        let obj = try JSONSerialization.jsonObject(with: data)
        guard let root = unwrapFlowRoot(obj) else {
            throw AuthError(code: .decoding, message: "Unexpected flow payload")
        }
        return try parseDictionary(root)
    }

    /// Handles bare flow, `{ "recovery": {...} }`, `{ "session": {...} }`, etc.
    static func unwrapFlowRoot(_ obj: Any) -> [String: Any]? {
        guard let dict = obj as? [String: Any] else { return nil }
        if dict["id"] != nil, dict["ui"] != nil { return dict }
        for key in ["login", "recovery", "verification", "settings", "setting", "registration"] {
            if let nested = dict[key] as? [String: Any], nested["id"] != nil {
                return nested
            }
        }
        return dict
    }

    static func parseSession(_ data: Data) throws -> Session {
        let obj = try JSONSerialization.jsonObject(with: data)
        let dict: [String: Any]
        if let root = obj as? [String: Any], let session = root["session"] as? [String: Any] {
            dict = session
        } else if let root = obj as? [String: Any], root["id"] != nil {
            dict = root
        } else {
            throw AuthError(code: .decoding, message: "Unexpected session payload")
        }
        return try decodeSession(dict)
    }

    static func parseDictionary(_ root: [String: Any]) throws -> ParsedFlow {
        guard let id = root["id"] as? String else {
            throw AuthError(code: .decoding, message: "Flow missing id")
        }
        let ui = root["ui"] as? [String: Any]
        let forms = ui?["forms"] as? [[String: Any]] ?? []
        var messages: [FlowMessage] = []
        var nodes: [FlowNodeAttributes] = []
        var formActions: [String] = []
        var formIds: [String] = []
        for form in forms {
            if let formId = form["id"] as? String {
                formIds.append(formId)
            }
            if let action = form["action"] as? String {
                formActions.append(action)
            }
            if let formMessages = form["messages"] as? [[String: Any]] {
                messages.append(contentsOf: formMessages.compactMap(parseMessage))
            }
            if let formNodes = form["nodes"] as? [[String: Any]] {
                for node in formNodes {
                    if let attrs = node["attributes"] as? [String: Any] {
                        nodes.append(
                            FlowNodeAttributes(
                                id: attrs["id"] as? String,
                                name: attrs["name"] as? String,
                                value: stringValue(attrs["value"]),
                                type: attrs["type"] as? String
                            )
                        )
                    }
                    if let nodeMessages = node["messages"] as? [[String: Any]] {
                        messages.append(contentsOf: nodeMessages.compactMap(parseMessage))
                    }
                }
            }
        }
        return ParsedFlow(
            id: id,
            type: root["type"] as? String,
            state: root["state"] as? String,
            active: root["active"] as? String,
            expiresAt: parseDate(root["expiresAt"]),
            messages: messages,
            nodes: nodes,
            formActions: formActions,
            formIds: formIds
        )
    }

    private static func parseMessage(_ dict: [String: Any]) -> FlowMessage? {
        guard let text = dict["text"] as? String else { return nil }
        var ctx: [String: String]?
        if let c = dict["context"] as? [String: Any] {
            ctx = c.reduce(into: [:]) { result, pair in
                result[pair.key] = stringValue(pair.value)
            }
        }
        let code: Int?
        if let i = dict["code"] as? Int {
            code = i
        } else if let s = dict["code"] as? String {
            code = Int(s)
        } else {
            code = nil
        }
        return FlowMessage(text: text, type: dict["type"] as? String, code: code, context: ctx)
    }

    private static func decodeSession(_ dict: [String: Any]) throws -> Session {
        guard let id = dict["id"] as? String else {
            throw AuthError(code: .decoding, message: "Session missing id")
        }
        var identity: Identity?
        if let identityDict = dict["identity"] as? [String: Any] {
            identity = Identity(
                subject: identityDict["subject"] as? String,
                userId: identityDict["userId"] as? String,
                source: identityDict["source"] as? String,
                username: identityDict["username"] as? String,
                email: identityDict["email"] as? String,
                emailVerified: identityDict["emailVerified"] as? Bool,
                mobile: identityDict["mobile"] as? String,
                mobileVerified: identityDict["mobileVerified"] as? Bool,
                locked: identityDict["locked"] as? Bool,
                firstName: identityDict["firstName"] as? String,
                middleName: identityDict["middleName"] as? String,
                lastName: identityDict["lastName"] as? String
            )
        } else if dict["identity"] is NSNull {
            identity = nil
        }
        return Session(
            id: id,
            userId: dict["userId"] as? String,
            active: dict["active"] as? Bool,
            expiresAt: parseDate(dict["expiresAt"]),
            authenticatedAt: parseDate(dict["authenticatedAt"]),
            authenticatorAssuranceLevel: dict["authenticatorAssuranceLevel"] as? String,
            identity: identity
        )
    }

    private static func stringValue(_ any: Any?) -> String? {
        switch any {
        case let s as String: return s
        case let i as Int: return String(i)
        case let d as Double: return String(d)
        case let b as Bool: return b ? "true" : "false"
        default: return nil
        }
    }

    private static func parseDate(_ any: Any?) -> Date? {
        guard let s = any as? String else { return nil }
        let f1 = ISO8601DateFormatter()
        f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f1.date(from: s) { return d }
        let f2 = ISO8601DateFormatter()
        f2.formatOptions = [.withInternetDateTime]
        return f2.date(from: s)
    }
}
