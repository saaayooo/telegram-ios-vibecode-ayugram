import Foundation

/// Pure policy, shared by the app and the standalone regression suite.
public struct NVXGramSettings: Equatable {
    public var ghostMode: Bool
    public var unreadMode: Bool

    public init(ghostMode: Bool = false, unreadMode: Bool = false) {
        self.ghostMode = ghostMode
        self.unreadMode = unreadMode
    }

    public func shouldPublishOnline(isActive: Bool) -> Bool {
        return isActive && !self.ghostMode
    }

    public func shouldSuppressAutomaticRead(isOrdinaryCloudChat: Bool, hasExpiringContent: Bool, timeoutIsKnownDisabled: Bool) -> Bool {
        return self.unreadMode && isOrdinaryCloudChat && !hasExpiringContent && timeoutIsKnownDisabled
    }
}

/// Local installation-wide preferences. No account credentials are stored here.
public final class NVXGramSettingsStore {
    private let defaults: UserDefaults
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    public var current: NVXGramSettings {
        return NVXGramSettings(ghostMode: self.defaults.bool(forKey: "nvxgram.ghostMode"), unreadMode: self.defaults.bool(forKey: "nvxgram.unreadMode"))
    }
    public func setGhostMode(_ value: Bool) {
        self.defaults.set(value, forKey: "nvxgram.ghostMode")
    }
    public func setUnreadMode(_ value: Bool) {
        self.defaults.set(value, forKey: "nvxgram.unreadMode")
    }
}
