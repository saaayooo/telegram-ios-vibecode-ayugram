import Foundation
import Postbox
import SwiftSignalKit

func nvxgramSuppressesAutomaticRead(transaction: Transaction, index: MessageIndex, hasExpiringContent: Bool? = nil) -> Bool {
    let settings = NVXGramPreferences.shared.current
    guard settings.unreadMode else { return false }
    let peerId = index.id.peerId
    let peer = transaction.getPeer(peerId)
    let ordinary = (peerId.namespace == Namespaces.Peer.CloudUser || peerId.namespace == Namespaces.Peer.CloudGroup || peerId.namespace == Namespaces.Peer.CloudChannel) && peer?.isForumOrMonoForum != true
    let cached = transaction.getPeerCachedData(peerId: peerId)
    let timeout: CachedPeerAutoremoveTimeout
    if let data = cached as? CachedUserData {
        timeout = data.autoremoveTimeout
    } else if let data = cached as? CachedGroupData {
        timeout = data.autoremoveTimeout
    } else if let data = cached as? CachedChannelData {
        timeout = data.autoremoveTimeout
    } else {
        timeout = .unknown
    }
    let knownDisabled: Bool
    switch timeout {
    case .known(nil): knownDisabled = true
    case let .known(value?): knownDisabled = value.effectiveValue <= 0
    case .unknown: knownDisabled = false
    }
    // Fail open for an unknown/missing message: never postpone expiry based on incomplete data.
    let expiring: Bool
    if let hasExpiringContent {
        expiring = hasExpiringContent
    } else if let message = transaction.getMessage(index.id) {
        expiring = message.containsSecretMedia || message.attributes.contains(where: {
            $0 is AutoremoveTimeoutMessageAttribute || $0 is AutoclearTimeoutMessageAttribute
        })
    } else {
        return false
    }
    return settings.shouldSuppressAutomaticRead(isOrdinaryCloudChat: ordinary, hasExpiringContent: expiring, timeoutIsKnownDisabled: knownDisabled)
}

func _internal_nvxgramApplyAutomaticRead(postbox: Postbox, stateManager: AccountStateManager, index: MessageIndex) -> Signal<Void, NoError> {
    return postbox.transaction { transaction -> Void in
        guard !nvxgramSuppressesAutomaticRead(transaction: transaction, index: index) else { return }
        _internal_applyMaxReadIndexInteractively(transaction: transaction, stateManager: stateManager, index: index)
    }
}
