# NVXGram v0.1

Экспериментальные изменения Telegram-iOS master. **Не собран, на iPhone не проверен.**

- [Отчёт и ограничения](REPORT.md)
- [GitHub Actions и действия владельца](OWNER_SETUP.md)
- [План проверки](TEST_PLAN.md)

`bash nvxgram/test.sh` запускает проверки исходников и Swift policy/storage tests на машине со Swift. Полная сборка запускается вручную через Actions с owner credentials. Публикации IPA/Release нет.

Изменения не заменяют настройки приватности Telegram. Секретные и исчезающие сообщения используют штатную обработку.
