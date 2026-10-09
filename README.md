# QR Flick

**Scan QR codes directly from your Mac screen.** Click the menu bar icon, select a region, inspect the address, then open it in your default browser or copy it.

[Website](https://kunilingvistador.github.io/QRFlick/) · [Download](https://github.com/kunilingvistador/QRFlick/releases) · [Install and permissions](https://kunilingvistador.github.io/QRFlick/en/guides/screen-recording-permission/)

## Everyday use

- Left-click the QR menu bar icon to scan. Right-click for settings and other inputs.
- Select the entire QR, including its margin. Escape or right-click cancels selection.
- Inspect the prominent domain and full address. Nothing opens automatically.
- Optional custom keyboard shortcut, compact result card and launch at login.
- Image-file drop, image files and clipboard images are secondary inputs.
- QR payloads such as text, Wi-Fi and contacts can be copied; only HTTP(S) URLs without embedded credentials get a browser button.

The application is named **QR Flick**. The bundle identifier remains `com.screenqr.app` to preserve existing settings and screen permission.

## Install

macOS 14+, Apple Silicon or Intel. Download the DMG, drag QR Flick into Applications and launch that copy. For screen scanning, allow Screen Recording when requested and restart if macOS asks. Image files and clipboard do not require screen permission.

**0.3.0 is an ad-hoc signed beta, without Developer ID or Apple notarization.** macOS may block the first launch. Verify the release source and checksum; use the normal macOS confirmation only if you trust this build. Do not disable system protections globally. Intel is cross-compiled; live testing on an Intel Mac is still needed. See [validation and remaining limits](docs/VALIDATION.md).

## Privacy

Apple Vision performs recognition on-device. During a screen scan, the app temporarily captures connected displays in memory, excludes its own windows, then recognizes QR codes inside the selected region. Screen Recording permission permits more than that region. The app saves no screenshot files or scan history, records no audio and has no telemetry. Copying sends text to the system clipboard; opening a link sends it to your default browser. The destination website receives a normal browser request. QR Flick does not verify website reputation.

Hotkey and result-display preferences are stored locally. GitHub hosts the website and downloads under its own privacy policy. The website includes opt-in Google Analytics for page views and download clicks. QR contents and screenshots are never sent. Never attach private QR contents to public issues.

## Build and check

Apple Command Line Tools, Swift 5.9+ and Python 3. No third-party Swift dependencies.

```sh
python3 scripts/build.py        # universal ZIP, DMG and SHA-256
python3 scripts/build.py --native
zsh scripts/check.sh
python3 scripts/build-website.py
python3 scripts/validate-website.py
```

Optional `SCREENQR_SIGN_IDENTITY` selects a Developer ID identity for hardened-runtime signing. Notarization is a separate release step; the build does not claim it has occurred. The default build uses ad-hoc signing. CI checks recognition, production URL/geometry policies and packaging; it cannot verify physical keyboard activation or real display behavior.

The native interface follows the first preferred macOS language: Russian or English. `--demo` opens onboarding with no preference reset; `--english` selects English for QA. These flags do not bypass screen permission.

## По-русски

QR Flick читает QR прямо с экрана Mac: нажмите значок в строке меню, выделите код, проверьте адрес и откройте ссылку. Скриншот сохранять не нужно. Горячая клавиша назначается в настройках и по умолчанию выключена. Ссылка никогда не открывается автоматически.

Бесплатная открытая бета для macOS 14+, Apple Silicon и Intel. Для сканирования нужен доступ к записи экрана. Распознавание локальное, история не сохраняется. Текущая сборка без нотариализации Apple; подробности установки и оставшихся проверок указаны выше.

## License

Code and original artwork: [MIT](LICENSE). Independent project; Apple and other product names belong to their respective owners.
