"""Source integration guards. These are not runtime or MTProto tests."""
import pathlib
import unittest
ROOT = pathlib.Path(__file__).resolve().parents[2]
def read(path):
    return (ROOT / path).read_text()
class Wiring(unittest.TestCase):
    def test_presence_native_transport_remains(self):
        s = read('submodules/TelegramCore/Sources/State/ManagedAccountPresence.swift')
        self.assertIn('combineLatest(shouldKeepOnlinePresence, NVXGramPreferences.shared.signal)', s)
        self.assertIn('settings.shouldPublishOnline(isActive: active)', s)
        self.assertIn('offline: .boolTrue', s)
        self.assertIn('offline: .boolFalse', s)
        self.assertNotIn('updatePresence(true)', s)
        # The offline branch must not cancel the foreground recovery timer.
        self.assertNotIn('} else {\n            self.onlineTimer?.invalidate()', s)
    def test_typing_guard_precedes_both_transports(self):
        s = read('submodules/TelegramCore/Sources/State/ManagedLocalInputActivities.swift')
        guard = s.index('NVXGramPreferences.shared.current.ghostMode')
        self.assertLess(guard, s.index('Api.functions.messages.setTyping'))
        self.assertLess(guard, s.index('Api.functions.messages.setEncryptedTyping'))
    def test_automatic_and_manual_reads_are_separate(self):
        s = read('submodules/TelegramUI/Sources/AccountContext.swift')
        self.assertIn('self.engine.messages.nvxgramApplyAutomaticRead(index: messageIndex)', s)
        s = read('submodules/TelegramCore/Sources/TelegramEngine/Messages/NVXGramAutomaticRead.swift')
        self.assertLess(s.index('guard !nvxgramSuppressesAutomaticRead'), s.index('_internal_applyMaxReadIndexInteractively'))
        native = read('submodules/TelegramCore/Sources/TelegramEngine/Messages/ApplyMaxReadIndexInteractively.swift')
        self.assertNotIn('NVXGram', native)
        self.assertIn('transaction.applyInteractiveReadMaxIndex(index)', native)
    def test_send_ack_restores_offline(self):
        s = read('submodules/TelegramCore/Sources/State/PendingMessageManager.swift')
        self.assertEqual(s.count('self?.nvxgramRestoreOfflineAfterSend()'), 2)
        self.assertIn('offline: .boolTrue', s)
    def test_store_hook_before_automatic_actions(self):
        s = read('submodules/TelegramCore/Sources/TelegramEngine/Messages/InstallInteractiveReadMessagesAction.swift')
        self.assertLess(s.index('nvxgramSuppressesAutomaticRead'), s.index('consumeMessageIds.append'))
        self.assertIn('threadId == nil, nvxgramSuppressesAutomaticRead', s)
if __name__ == '__main__':
    unittest.main()
