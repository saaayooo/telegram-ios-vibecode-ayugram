# Облако, без локального Mac

1. Создайте пустой private GitHub repository NVXGram из Safari на iPhone. Разрешите подключённой интеграции доступ к нему, включая contents и workflows. Передайте URL, секреты в чат не присылайте.
2. После загрузки исходников автоматически запустится job `verify`. Он проверит Xcode 27.1, Swift-политику/хранение и синтаксис изменённых файлов. Он не компилирует приложение целиком. Образ `xcode-27` находится в preview, доступность runner зависит от аккаунта/тарифа GitHub.
3. Получите собственные Telegram API ID и API hash на https://my.telegram.org/apps. Храните их в GitHub → Settings → Secrets and variables → Actions: `NVX_API_ID`, `NVX_API_HASH`.
4. Для установки на iPhone нужна подходящая подпись Apple и provisioning с UDID устройства (development/Ad Hoc). Локальный Mac для запуска сборки не требуется; нужны права Apple Developer и подготовка ключа/CSR/сертификата в доверенной облачной среде. Это следующий отдельный шаг с владельцем, текущие исходники ключей не создают.
5. Подготовленный Bundle ID: `org.nvxgram.ios`. Зарегистрируйте его и ID расширений с entitlements по шаблонам `build-system/fake-codesigning/profiles` (не используйте сами fake profiles): `.Share`, `.NotificationContent`, `.NotificationService`, `.Widget`, `.BroadcastUpload`; проверьте `.SiriIntents` согласно конфигурации. App Groups/Keychain Groups должны соответствовать вашему bundle/team. Siri и iCloud выключены в минимальной конфигурации. Не используйте официальный Bundle ID Telegram. Если имя занято, замените его одновременно в `prepare_build.py` и workflow-проверке bundle.
6. Добавьте Actions secrets:
   - `NVX_TEAM_ID` — Apple Team ID.
   - `NVX_CERTIFICATE_P12_BASE64` — base64 вашего signing certificate с private key в P12.
   - `NVX_CERTIFICATE_PASSWORD` — непустой пароль P12.
   - `NVX_PROFILES_ZIP_BASE64` — base64 ZIP только с `.mobileprovision` для приложения и нужных расширений. Имена файлов произвольные: Make.py сопоставляет application-identifier. Соблюдайте лимит размера GitHub Secrets; архив должен в него помещаться.
7. Actions → NVXGram v0.1 → Run workflow → `build_ipa: true`. Секреты поступают только через environment одного шага, material создаётся в RUNNER_TEMP, ephemeral keychain удаляется `always()`. Никаких ключей, ZIP, JSON с credentials и provisioning не коммитить. Не запускайте сборку недоверенных веток с секретами.
8. Только после успешной сборки и проверок появится Artifact `NVXGram-v0.1-arm64-unverified-on-device`, срок 7 дней. Это не Release, не TestFlight и не автоматическая установка на телефон. Проверьте через TEST_PLAN.md перед распространением.

На штатном небольшом hosted runner полная Telegram-сборка может упереться в RAM/диск/6-часовой лимит. Результат пока неизвестен; потребуется более крупный macOS runner при подтверждённой нехватке ресурсов. Приватные Actions могут расходовать квоту/биллинг аккаунта.
