import Foundation

struct BrowserInfo: Codable, Equatable, Hashable {
    let name: String
    let bundleIdentifier: String
    let path: String

    var icon: NSImage? {
        NSWorkspace.shared.icon(forFile: path)
    }
}

struct Rule: Codable, Identifiable {
    let id: UUID
    var pattern: String
    var browserBundleID: String
    var isEnabled: Bool

    init(pattern: String, browserBundleID: String, isEnabled: Bool = true) {
        self.id = UUID()
        self.pattern = pattern
        self.browserBundleID = browserBundleID
        self.isEnabled = isEnabled
    }

    func matches(url: URL) -> Bool {
        guard isEnabled else { return false }
        let urlString = url.absoluteString.lowercased()
        let host = url.host?.lowercased() ?? ""

        // Support simple wildcard patterns
        let p = pattern.lowercased()
        if p.hasPrefix("*.") {
            let suffix = String(p.dropFirst(1)) // ".example.com"
            return host.hasSuffix(suffix) || host == String(suffix.dropFirst())
        }
        return host.contains(p) || urlString.contains(p)
    }
}

import AppKit
