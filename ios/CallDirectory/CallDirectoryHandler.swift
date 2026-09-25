import CallKit
import Foundation

/// iOS asks this extension for the numbers to block and to label ("Spam – Telemarketing").
/// The app writes both lists into the shared App Group container, already sorted
/// ascending and de-duplicated (CallKit requires it): one "number<TAB>label" per line,
/// number = digits with country code, e.g. 390212345678.
final class CallDirectoryHandler: CXCallDirectoryProvider {
    static let group = "group.com.konechoco.blacklist"

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self
        guard let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.group) else {
            context.completeRequest()
            return
        }
        // Full reload every time: the lists are small (one country) and this keeps state simple.
        forEachLine(dir.appendingPathComponent("block.txt")) { number, _ in
            context.addBlockingEntry(withNextSequentialPhoneNumber: number)
        }
        forEachLine(dir.appendingPathComponent("identify.txt")) { number, label in
            context.addIdentificationEntry(withNextSequentialPhoneNumber: number, label: label)
        }
        context.completeRequest()
    }

    private func forEachLine(_ url: URL, _ body: (CXCallDirectoryPhoneNumber, String) -> Void) {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return }
        var last: CXCallDirectoryPhoneNumber = 0
        for line in text.split(separator: "\n") {
            let parts = line.split(separator: "\t", maxSplits: 1)
            guard let first = parts.first, let number = CXCallDirectoryPhoneNumber(first), number > last else { continue }
            last = number
            body(number, parts.count > 1 ? String(parts[1]) : "Spam")
        }
    }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {}
}
