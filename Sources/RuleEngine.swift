import Foundation

final class RuleEngine {
    static let shared = RuleEngine()

    private let rulesKey = "LinkDispatchRules"
    private let defaultBrowserKey = "LinkDispatchDefaultBrowser"
    private let promptAlwaysKey = "LinkDispatchPromptAlways"

    var rules: [Rule] {
        get {
            guard let data = UserDefaults.standard.data(forKey: rulesKey),
                  let decoded = try? JSONDecoder().decode([Rule].self, from: data) else { return [] }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: rulesKey)
            }
        }
    }

    var defaultBrowserBundleID: String? {
        get { UserDefaults.standard.string(forKey: defaultBrowserKey) }
        set { UserDefaults.standard.set(newValue, forKey: defaultBrowserKey) }
    }

    var promptAlways: Bool {
        get { UserDefaults.standard.bool(forKey: promptAlwaysKey) }
        set { UserDefaults.standard.set(newValue, forKey: promptAlwaysKey) }
    }

    /// Returns the browser bundle ID to use for a URL, or nil if the picker should be shown.
    func resolve(url: URL) -> String? {
        if promptAlways { return nil }

        // Check rules first (first match wins)
        for rule in rules where rule.isEnabled {
            if rule.matches(url: url) {
                return rule.browserBundleID
            }
        }

        // Fall back to default browser
        return defaultBrowserBundleID
    }
}
