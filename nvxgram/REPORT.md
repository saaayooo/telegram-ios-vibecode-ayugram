# NVXGram v0.1 — отчёт от 2026-11-11

**Статус: исходники экспериментального прототипа. Работоспособность iOS-клиента не подтверждена. IPA не собран и не опубликован.**

Основа: TelegramMessenger/Telegram-iOS, master, `24638bc69bd083981b178dd1e7f921eebbf7fc46` (HEAD удалённого master на момент clone). Прочитаны README.md, CLAUDE.md, AGENTS.md, versions.json и инструкции build-system/Make. Upstream version 13.2 сохранена для совместимости сборки; v0.1 — версия модификаций NVXGram.

## Реализовано и проверено

- Найдены реальные запросы presence, typing и read state; карта ниже.
- Добавлены пять Python-проверок связей исходников: `python3 -m unittest discover -s nvxgram/tests -v` — 5/5 PASS в Linux. Это проверки исходников, **не** проверка запросов к Telegram.
- `python3 build-system/Make/PostboxImportCheck.py` — PASS.
- `python3 -m py_compile nvxgram/prepare_build.py` — PASS.
- `git diff --check`, `bash -n nvxgram/test.sh`, YAML parse и базовые проверки workflow — PASS.
- Проверен отказ `prepare_build.py` при отсутствии секретов: остановка до создания signing material, перечислены только имена отсутствующих secrets.
- Доступность Xcode 27.1 подтверждена в опубликованном списке образа GitHub `xcode-27` (image 20261104.0337.1, Xcode build 27A9275). Реального runner пока нет.
- Удалён upstream workflow, публиковавший Release на push. Новый workflow сохраняет только Artifact после ручного запуска сборки; прав на создание Release нет.

## Реализовано, но не проверено на устройстве

Всё перечисленное ниже — изменения исходников, ожидающие компиляции, тестов на macOS и проверки с двумя аккаунтами.

- Settings → NVXGram: два нативных переключателя, оба OFF по умолчанию. UserDefaults сохраняет настройки для установки приложения, сразу для всех аккаунтов; аккаунтные данные там не хранятся.
- Ghost: `AccountPresenceManager` получает настройку до первого запроса; при включении и работе в foreground запрашивает offline вместо online, повторяет раз в 30 секунд. В background повторения прекращаются. Выключение возвращает штатный online.
- Ghost: подавляется весь обычный поток локальных input activities, включая typing/запись/загрузку и encrypted typing. Завершение входящего live draft через Stop оставлено штатным: это управляющее действие, не исходящий индикатор печати.
- После подтверждённой отправки одиночного сообщения или альбома PendingMessageManager запрашивает offline. Ошибки offline не влияют на результат отправки. Периодический foreground offline — дополнительная попытка восстановления.
- Нечиталка: обычные облачные личные чаты, группы и каналы без форумов/тем. Автоматический read блокируется **до** изменения локального read index и постановки операции синхронизации. Аналогичный фильтр применяется к новым сообщениям в открытой истории.
- При неизвестных cached TTL, неизвестном сообщении, secret media, Autoremove/Autoclear используется штатное чтение. Отложенная очередь read для заблокированных автоматических просмотров не создаётся.
- Ручное «Прочитать»/«Прочитать всё» в списке чатов использует исходный interactive API и продолжает синхронизироваться. При отключении нечиталки откройте чат заново, чтобы применилось штатное чтение уже видимой истории.
- Авторизация, запросы updates/difference, transport keepalive, загрузка истории, входящие read updates других сеансов и синхронизация pending операций не изменены. Это не доказывает отсутствие регрессий — требуется полноценный запуск.
- Добавлены 24 Swift-проверки таблиц политики и пересоздания persistent store (`bash nvxgram/test.sh`); **не запускались**, Swift/Xcode в Linux-среде отсутствуют. Это тесты решений и хранения, не интеграционный тест сети и не перезапуск iOS-процесса.
- Workflow: macOS `xcode-27`, проверка точной версии из versions.json без override, Swift tests + syntax parse, отдельный ручной build `release_arm64`, отдельный Bundle ID `org.nvxgram.ios`, временная подпись через Secrets, проверка bundle/arm64/signature, Artifact на 7 дней. **Workflow ещё не запускался; полный type check не выполнен.**

## Ограничено сервером Telegram

- Запрос offline не отменяет действий других активных клиентов и не гарантирует исчезновение online мгновенно.
- Отправка сообщения, typing и прочтение личного сообщения могут временно показывать online по правилам Telegram. Ghost без нечиталки сохраняет штатные read receipts; поэтому не обещает невидимость при чтении. Для ordinary cloud history включайте оба режима.
- Настройки «Последняя активность и в сети» и их исключения остаются настройками сервера. NVXGram их не меняет. Ограничения видимости статуса других людей также остаются штатными.
- Другой клиент, ручное чтение, ответ из уведомления или Siri могут отметить чат прочитанным. Клиент не может вернуть уже отправленное подтверждение; unread mark не отменяет blue ticks.
- Прослушивание/открытие медиа, mentions/reactions, просмотры каналов/stories, звонки, read metrics и прочие действия не обещаны анонимными. Нечиталка v0.1 блокирует автоматический read history, а не любой возможный сигнал просмотра.
- Не отменяются серверные удаления, TTL и view-once. Секретные чаты и исчезающий контент сохраняют штатные ограничения и квитанции.

## Не реализовано

- Подтверждённый рабочий клиент с авторизацией: нет результата компиляции, входа в аккаунт и проверки на iPhone.
- Сетевые интеграционные тесты с реальным сервером/двумя аккаунтами и запись UI на симуляторе. Инструкция AGENTS.md требует кадры для подтверждения UI; таких доказательств нет.
- Нечиталка для секретных чатов, тем, комментариев, disappearing/view-once и чатов с неизвестным TTL — намеренно вне области реализации.
- Установочный IPA/Artifact: без owner API credentials и Apple signing его нет.
- Регистрация Bundle ID в Apple Developer, сертификат и profiles для приложения/расширений: требует владельца. `org.nvxgram.ios` — подготовленный идентификатор, ещё не зарегистрированный.
- Отдельная иконка NVXGram: upstream assets сохранены; перед распространением нужна собственная иконка по условиям README. Имя приложения изменено на NVXGram, экспериментальный характер указан в настройках.

## Блокер GitHub

`gh auth status` подтверждает подключение аккаунта saaayooo. Попытка создать private `saaayooo/NVXGram` отклонена GitHub: `GraphQL: Resource not accessible by integration (createRepository)`. Репозиторий не создан; исходники никуда не отправлены. Нужен URL пустого private-репозитория, созданного владельцем, с доступом интеграции на запись contents и workflows. Ошибка GitHub API — не отказ автоматической проверки одобрения.

## Карта механизмов

| Механизм | Источник | Решение v0.1 |
| --- | --- | --- |
| `account.updateStatus(offline:)` | TelegramCore/State/ManagedAccountPresence.swift | Offline при Ghost, online подавлен на уровне менеджера |
| `messages.setTyping`, `setEncryptedTyping` | TelegramCore/State/ManagedLocalInputActivities.swift | Не посылаются при Ghost |
| `setTyping(sendMessageStopDraftAction)` | TelegramCore/State/TypingDraftStop.swift | Сохранён управляющий Stop |
| `Network.isUserOnline`, `NetworkEngine.setOnline` | Account/Account.swift; Network/*Engine.swift | Не меняются: управляют транспортом/keepalive, не RPC presence; MtProtoKitEngine.setOnline — no-op |
| Visible max incoming index | TelegramUI/ChatHistoryListNode.swift → AccountContext.swift | Новый automatic API с фильтром до транзакционного read |
| Incoming сообщения открытого чата | TelegramEngine/Messages/InstallInteractiveReadMessagesAction.swift | Фильтр перед read/автоматическими действиями для ordinary cloud history |
| `messages.readHistory`, `channels.readHistory` | State/SynchronizePeerReadState.swift | Синхронизатор оставлен целым; новый автоматический read не попадает в него |
| `readEncryptedHistory` и countdown | SynchronizePeerReadState.swift; ApplyMaxReadIndexInteractively.swift | Штатное поведение |
| `readDiscussion`, `readSavedHistory` | ReplyThreadHistory.swift и interactive forum actions | Штатное поведение, темы вне scope |
| Ручное прочтение | ApplyMaxReadIndexInteractively.swift, MarkAllChatsAsRead.swift, interactive chat-list actions | Без фильтра |

Ссылки: [runner image](https://github.com/actions/runner-images/blob/main/images/macos/xcode-27-arm64-Readme.md), [runner labels](https://github.com/actions/runner-images), [online privacy](https://telegram.org/faq#q-who-can-see-me-online), [account.updateStatus](https://core.telegram.org/method/account.updateStatus), [messages.readHistory](https://core.telegram.org/method/messages.readHistory).
