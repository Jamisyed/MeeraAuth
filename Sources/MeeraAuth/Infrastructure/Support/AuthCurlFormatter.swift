//
//  AuthCurlFormatter.swift
//  MeeraAuth
//
//  Created by Syed M Abdul Rehman on 05/08/2026.
//

import Foundation

enum AuthCurlFormatter {
    static func requestLog(
        for request: AuthHTTPRequest,
        mode: AuthNetworkLogging
    ) -> String {
        guard mode.isEnabled else { return "" }

        var lines: [String] = [
            "",
            banner("START · \(modeLabel(mode))"),
            "→ REQUEST",
            "\(request.method.uppercased()) \(request.url.absoluteString)",
            "",
            curlCommand(for: request, redact: mode.redactSensitiveValues),
        ]

        if mode == .curl {
            lines.append("")
            lines.append(banner("END"))
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    static func responseLog(
        _ response: AuthHTTPResponse,
        mode: AuthNetworkLogging,
        duration: Duration? = nil
    ) -> String {
        guard mode.includesResponse else { return "" }

        let meta = responseMeta(
            statusCode: response.statusCode,
            byteCount: response.data.count,
            duration: duration
        )
        var lines: [String] = [
            "",
            "← RESPONSE  \(meta)",
        ]

        let body = formattedBody(response.data, redact: mode.redactSensitiveValues)
        if !body.isEmpty {
            lines.append(body)
        }
        lines.append(banner("END"))
        lines.append("")
        return lines.joined(separator: "\n")
    }

    static func errorLog(
        _ error: Error,
        mode: AuthNetworkLogging,
        duration: Duration? = nil
    ) -> String {
        guard mode.includesResponse else { return "" }

        let timing = duration.map(formatDuration).map { " · \($0)" } ?? ""
        var lines: [String] = [
            "",
            "← RESPONSE  ERROR\(timing)",
        ]

        if let authError = error as? AuthError {
            lines.append("code: \(authError.code.rawValue)")
            lines.append("message: \(authError.message)")
            if let status = authError.httpStatus {
                lines.append("httpStatus: \(status)")
            }
        } else {
            lines.append("message: \(error.localizedDescription)")
        }

        lines.append(banner("END"))
        lines.append("")
        return lines.joined(separator: "\n")
    }

    static func curl(
        for request: AuthHTTPRequest,
        redactSensitiveValues: Bool
    ) -> String {
        requestLog(for: request, mode: redactSensitiveValues ? .log : .verbose)
    }

    static func responseSummary(
        statusCode: Int,
        data: Data,
        duration: Duration? = nil,
        redactSensitiveValues: Bool = false
    ) -> String {
        responseLog(
            AuthHTTPResponse(statusCode: statusCode, data: data),
            mode: redactSensitiveValues ? .log : .verbose,
            duration: duration
        )
    }

    private static let bannerWidth = 64

    private static func curlCommandLines(
        for request: AuthHTTPRequest,
        redact: Bool
    ) -> [String] {
        var lines: [String] = ["$ curl -v \\"]

        let method = request.method.uppercased()
        if method != "GET" {
            lines.append("\t-X \(method) \\")
        }

        let headers = request.headers.sorted {
            $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending
        }
        for (key, value) in headers {
            let headerValue = redact && isSensitiveHeader(key)
                ? redactedHeaderValue(value)
                : value
            lines.append("\t-H \"\(escape(key)): \(escape(headerValue))\" \\")
        }

        if let body = request.body, !body.isEmpty {
            let bodyString = bodyForLog(body, redact: redact)
            lines.append("\t-d \"\(escape(bodyString))\" \\")
        }

        lines.append("\t\"\(escape(request.url.absoluteString))\"")
        return lines
    }

    private static func curlCommand(
        for request: AuthHTTPRequest,
        redact: Bool
    ) -> String {
        curlCommandLines(for: request, redact: redact).joined(separator: "\n")
    }

    private static func banner(_ title: String) -> String {
        let label = " MeeraAuth · \(title) "
        let pad = max(0, bannerWidth - label.count)
        let left = pad / 2
        let right = pad - left
        return String(repeating: "━", count: left) + label + String(repeating: "━", count: right)
    }

    private static func modeLabel(_ mode: AuthNetworkLogging) -> String {
        switch mode {
        case .off: return "off"
        case .log: return "log"
        case .verbose: return "verbose"
        case .curl: return "curl"
        }
    }

    private static func responseMeta(
        statusCode: Int,
        byteCount: Int,
        duration: Duration?
    ) -> String {
        var parts = ["HTTP \(statusCode)"]
        if let duration {
            parts.append(formatDuration(duration))
        }
        parts.append(formatBytes(byteCount))
        return parts.joined(separator: " · ")
    }

    private static func formatDuration(_ duration: Duration) -> String {
        let ms = Double(duration.components.seconds) * 1_000
            + Double(duration.components.attoseconds) / 1e15
        if ms < 1 {
            return String(format: "%.2fms", ms)
        }
        if ms < 1_000 {
            return String(format: "%.0fms", ms)
        }
        return String(format: "%.2fs", ms / 1_000)
    }

    private static func formatBytes(_ count: Int) -> String {
        if count < 1_024 { return "\(count) B" }
        return String(format: "%.1f KB", Double(count) / 1_024)
    }

    private static func formattedBody(
        _ data: Data,
        redact: Bool,
        maxLength: Int = 8_192
    ) -> String {
        guard !data.isEmpty else { return "" }

        var text = bodyForLog(data, redact: redact)
        text = prettyPrintedJSON(text) ?? text

        if text.count > maxLength {
            return String(text.prefix(maxLength)) + "\n…[truncated \(text.count - maxLength) chars]"
        }
        return text
    }

    private static func prettyPrintedJSON(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.first == "{" || trimmed.first == "[" else { return nil }
        guard let data = trimmed.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(
                withJSONObject: object,
                options: [.prettyPrinted, .sortedKeys]
              ),
              let string = String(data: pretty, encoding: .utf8)
        else {
            return nil
        }
        return string
    }

    private static func isSensitiveHeader(_ key: String) -> Bool {
        let lower = key.lowercased()
        return lower == "authorization" || lower == "cookie" || lower == "x-session-id"
    }

    private static func redactedHeaderValue(_ value: String) -> String {
        if value.lowercased().hasPrefix("bearer "), value.count > 20 {
            let token = value.dropFirst(7)
            let prefix = token.prefix(8)
            return "Bearer \(prefix)…[redacted]"
        }
        if value.count > 12 {
            return String(value.prefix(6)) + "…[redacted]"
        }
        return "[redacted]"
    }

    private static func bodyForLog(_ data: Data, redact: Bool) -> String {
        guard var text = String(data: data, encoding: .utf8) else {
            return "<binary \(data.count) bytes>"
        }
        if redact {
            text = redactJSONSecrets(in: text)
            text = redactFormSecrets(in: text)
        }
        return text
    }

    private static func redactJSONSecrets(in text: String) -> String {
        let keys = [
            "password", "confirmPassword", "code",
            "access_token", "refresh_token", "id_token",
            "accessToken", "refreshToken", "idToken",
        ]
        var result = text
        for key in keys {
            let pattern = "\"\(key)\"\\s*:\\s*\"([^\"]*)\""
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(result.startIndex..<result.endIndex, in: result)
                result = regex.stringByReplacingMatches(
                    in: result,
                    options: [],
                    range: range,
                    withTemplate: "\"\(key)\":\"[redacted]\""
                )
            }
        }
        return result
    }

    private static func redactFormSecrets(in text: String) -> String {
        guard text.contains("="),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{")
        else {
            return text
        }
        let sensitive = Set(["password", "confirmpassword", "code"])
        return text.split(separator: "&").map { pair -> String in
            let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { return String(pair) }
            if sensitive.contains(parts[0].lowercased()) {
                return "\(parts[0])=[redacted]"
            }
            return String(pair)
        }.joined(separator: "&")
    }

    private static func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
