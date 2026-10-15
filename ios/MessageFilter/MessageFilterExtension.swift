import Foundation
import IdentityLookup

/// iOS SMS/MMS filter for messages from unknown senders (Settings › Apps ›
/// Messages › Unknown & Spam › Blacklist). Runs fully offline: the app writes
/// the rules, the user's keywords and the community spam numbers into the
/// App Group as sms_filter.json; nothing leaves the device.
final class MessageFilterExtension: ILMessageFilterExtension {}

extension MessageFilterExtension: ILMessageFilterQueryHandling {
    static let group = "group.com.konechoco.blacklist"

    func handle(_ queryRequest: ILMessageFilterQueryRequest,
                context: ILMessageFilterExtensionContext,
                completion: @escaping (ILMessageFilterQueryResponse) -> Void) {
        let response = ILMessageFilterQueryResponse()
        response.action = Self.action(sender: queryRequest.sender ?? "", body: queryRequest.messageBody ?? "")
        completion(response)
    }

    static func action(sender: String, body: String) -> ILMessageFilterAction {
        guard let rules = Rules.load() else { return .none }
        let digits = sender.filter(\.isNumber)
        if !digits.isEmpty {
            if rules.allowedSenders.contains(where: { digits.hasSuffix($0) || $0.hasSuffix(digits) }) { return .allow }
            if rules.spamSenders.contains(where: { $0.count >= 6 && (digits.hasSuffix($0) || $0.hasSuffix(digits)) }) { return .junk }
        }
        return rules.score(body) >= rules.threshold ? .junk : .none
    }
}

private struct Rules {
    struct Signal { let id: String; let weight: Int; let regex: NSRegularExpression }

    let threshold: Int
    let signals: [Signal]
    let keywords: [String]
    let keywordWeight: Int
    let spamSenders: Set<String>
    let allowedSenders: [String]

    static func load() -> Rules? {
        guard let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: MessageFilterExtension.group),
              let data = try? Data(contentsOf: dir.appendingPathComponent("sms_filter.json")),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        let signals = (json["signals"] as? [[String: Any]] ?? []).compactMap { s -> Signal? in
            guard let id = s["id"] as? String, let weight = s["weight"] as? Int, let pattern = s["pattern"] as? String,
                  let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
            return Signal(id: id, weight: weight, regex: regex)
        }
        return Rules(
            threshold: json["threshold"] as? Int ?? 5,
            signals: signals,
            keywords: (json["keywords"] as? [String] ?? []).map { $0.lowercased() }.filter { !$0.isEmpty },
            keywordWeight: json["keywordWeight"] as? Int ?? 5,
            spamSenders: Set(json["spamSenders"] as? [String] ?? []),
            allowedSenders: json["allowedSenders"] as? [String] ?? []
        )
    }

    /// Same scoring as lib/services/scam_rules.dart (analyzeMessage).
    func score(_ text: String) -> Int {
        let range = NSRange(text.startIndex..., in: text)
        var total = 0
        var hit = Set<String>()
        for s in signals {
            if s.id == "link" && (hit.contains("link_short") || hit.contains("link_odd")) { continue }
            if s.regex.firstMatch(in: text, range: range) != nil {
                total += s.weight
                hit.insert(s.id)
            }
        }
        let lower = text.lowercased()
        if keywords.contains(where: { lower.contains($0) }) { total += keywordWeight }
        return total
    }
}
