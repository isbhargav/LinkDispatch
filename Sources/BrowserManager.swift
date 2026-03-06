import AppKit

final class BrowserManager {
    static let shared = BrowserManager()

    private(set) var browsers: [BrowserInfo] = []
    private let selfBundleID = Bundle.main.bundleIdentifier ?? "com.linkdispatch.app"

    func refresh() {
        let httpURL = URL(string: "https://example.com")!
        var found: [BrowserInfo] = []
        var seen = Set<String>()

        if let appURLs = LSCopyApplicationURLsForURL(httpURL as CFURL, .all)?.takeRetainedValue() as? [URL] {
            for appURL in appURLs {
                guard let bundle = Bundle(url: appURL),
                      let bundleID = bundle.bundleIdentifier,
                      !seen.contains(bundleID),
                      bundleID != selfBundleID else { continue }
                seen.insert(bundleID)

                let name = bundle.infoDictionary?["CFBundleName"] as? String
                    ?? bundle.infoDictionary?["CFBundleDisplayName"] as? String
                    ?? appURL.deletingPathExtension().lastPathComponent

                found.append(BrowserInfo(
                    name: name,
                    bundleIdentifier: bundleID,
                    path: appURL.path
                ))
            }
        }

        // Sort alphabetically, but put common browsers first
        let priority = ["Safari", "Google Chrome", "Firefox", "Arc", "Brave Browser", "Microsoft Edge", "Opera"]
        browsers = found.sorted { a, b in
            let ai = priority.firstIndex(of: a.name) ?? Int.max
            let bi = priority.firstIndex(of: b.name) ?? Int.max
            if ai != bi { return ai < bi }
            return a.name < b.name
        }
    }

    func open(url: URL, with browser: BrowserInfo) {
        NSWorkspace.shared.open(
            [url],
            withApplicationAt: URL(fileURLWithPath: browser.path),
            configuration: NSWorkspace.OpenConfiguration()
        )
    }

    func open(url: URL, withBundleID bundleID: String) {
        guard let browser = browsers.first(where: { $0.bundleIdentifier == bundleID }) else { return }
        open(url: url, with: browser)
    }
}
