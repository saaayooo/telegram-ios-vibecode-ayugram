import Foundation
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import ItemListUI
import AccountContext

private enum NVXGramEntry: ItemListNodeEntry {
    case ghost(Bool)
    case unread(Bool)
    case info

    var section: ItemListSectionId { return 0 }
    var stableId: Int32 {
        switch self {
        case .ghost: return 0
        case .unread: return 1
        case .info: return 2
        }
    }
    static func < (lhs: NVXGramEntry, rhs: NVXGramEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        switch self {
        case let .ghost(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Ghost Mode", value: value, sectionId: self.section, style: .blocks, updated: {
                NVXGramPreferences.shared.setGhostMode($0)
            })
        case let .unread(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Нечиталка", value: value, sectionId: self.section, style: .blocks, updated: {
                NVXGramPreferences.shared.setUnreadMode($0)
            })
        case .info:
            return ItemListTextItem(presentationData: presentationData, text: .plain("NVXGram v0.1 — экспериментальные функции. Настройки действуют для всех аккаунтов на этом устройстве. Ghost Mode скрывает online и typing; сервер может показать online после отправки или подтверждения прочтения. Для скрытого чтения обычных чатов включите также нечиталку. Проверьте Telegram → Конфиденциальность → Последняя активность. Нечиталка действует только в обычных облачных чатах без таймеров. Секретные чаты, темы и исчезающие сообщения работают штатно. При неизвестном таймере используется штатное прочтение. Для ручного прочтения используйте «Прочитать» в списке чатов. Другие сеансы могут прочитать сообщения."), sectionId: self.section)
        }
    }
}

public func nvxgramSettingsController(context: AccountContext) -> ViewController {
    let signal = combineLatest(context.sharedContext.presentationData, NVXGramPreferences.shared.signal)
    |> deliverOnMainQueue
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let data = ItemListPresentationData(presentationData)
        let state = ItemListControllerState(presentationData: data, title: .text("NVXGram"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let entries: [NVXGramEntry] = [.ghost(settings.ghostMode), .unread(settings.unreadMode), .info]
        return (state, (ItemListNodeState(presentationData: data, entries: entries, style: .blocks, animateChanges: false), ()))
    }
    return ItemListController(context: context, state: signal)
}
