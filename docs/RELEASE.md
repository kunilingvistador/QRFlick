# ScreenQR 0.2.0 beta

Read a QR code directly from your Mac screen: click the menu bar icon, select the code, inspect the address and Open or Copy. The app never opens a result automatically.

This release adds an original icon, Russian/English UI, a cancelable recognition indicator, compact/full result cards, image orientation handling, and universal Apple Silicon/Intel packaging. It excludes its own windows from capture and fixes result-list placement and size. The optional keyboard shortcut is off by default for new users. The original unsafe Command–Shift–Q assignment has been removed and cannot be recorded.

Download the DMG and drag ScreenQR into Applications. ZIP is an alternative. macOS 14+ is required. Allow Screen Recording when first scanning, then restart if requested. The native app does not record audio, upload screenshots or save scan history.

**Development beta: ad-hoc signed, not Developer ID signed or notarized by Apple.** Verify the GitHub source and SHA-256 before trusting a download; macOS may require standard launch confirmation. Do not disable system protections. This release is not described as fully validated on every Mac: Intel is cross-compiled; additional hardware, macOS versions, fullscreen/Spaces, login startup and physical global shortcut checks remain.

Checks: universal compilation and archive integrity; six Vision payload cases; 12 URL-policy and five screen-geometry cases; live screen recognition on one Apple Silicon Mac; image file with multiple QR cards; static site validation for 12 Russian/English pages. See docs/VALIDATION.md for exact boundaries.

## По-русски

QR прямо с экрана: нажмите значок ScreenQR наверху, выделите код, проверьте адрес и нажмите «Открыть» или «Скопировать». Телефон и сохранение скриншота не нужны.

Откройте DMG и перенесите приложение в «Программы». Требуется macOS 14+. Для сканирования экрана разрешите запись экрана. Горячая клавиша необязательна и назначается в настройках. Распознавание локальное; автоматического перехода нет.

Это открытая бета без нотариализации Apple. Сборка содержит Intel и Apple Silicon; дополнительные проверки на реальных Mac остаются. Подробности проверки и ограничения перечислены выше.
