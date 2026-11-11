import Foundation
import SwiftSignalKit

public final class NVXGramPreferences {
    public static let shared = NVXGramPreferences()
    private let store = NVXGramSettingsStore()
    private let changes: ValuePromise<NVXGramSettings>

    private init() {
        self.changes = ValuePromise(self.store.current, ignoreRepeated: true)
    }
    public var current: NVXGramSettings {
        return self.store.current
    }
    public var signal: Signal<NVXGramSettings, NoError> {
        return self.changes.get()
    }
    // Settings UI writes on the main queue; readers may use any queue.
    public func setGhostMode(_ value: Bool) {
        self.store.setGhostMode(value)
        self.changes.set(self.store.current)
    }
    public func setUnreadMode(_ value: Bool) {
        self.store.setUnreadMode(value)
        self.changes.set(self.store.current)
    }
}
