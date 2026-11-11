import Foundation

var checks = 0
func expect(_ condition: @autoclosure () -> Bool, _ description: String) {
    checks += 1
    if !condition() { fatalError(description) }
}
for ghost in [false, true] {
    for active in [false, true] {
        let settings = NVXGramSettings(ghostMode: ghost)
        expect(settings.shouldPublishOnline(isActive: active) == (active && !ghost), "Online policy: ghost=\(ghost), active=\(active)")
    }
}
for unread in [false, true] {
    for ordinary in [false, true] {
        for expiring in [false, true] {
            for knownDisabled in [false, true] {
                let value = NVXGramSettings(unreadMode: unread).shouldSuppressAutomaticRead(isOrdinaryCloudChat: ordinary, hasExpiringContent: expiring, timeoutIsKnownDisabled: knownDisabled)
                expect(value == (unread && ordinary && !expiring && knownDisabled), "Read policy truth table")
            }
        }
    }
}
let suite = "nvxgram.tests.\(UUID().uuidString)"
let defaults = UserDefaults(suiteName: suite)!
defer { defaults.removePersistentDomain(forName: suite) }
let first = NVXGramSettingsStore(defaults: defaults)
expect(first.current == NVXGramSettings(), "New installation defaults OFF")
first.setGhostMode(true)
first.setUnreadMode(true)
let reopened = NVXGramSettingsStore(defaults: UserDefaults(suiteName: suite)!)
expect(reopened.current == NVXGramSettings(ghostMode: true, unreadMode: true), "Preferences survive store recreation")
reopened.setGhostMode(false)
expect(first.current == NVXGramSettings(ghostMode: false, unreadMode: true), "Independent switches")
reopened.setUnreadMode(false)
expect(first.current == NVXGramSettings(), "Return to native behavior")
print("PASS: \(checks) NVXGram policy/persistence checks. Network and device behavior NOT tested.")
