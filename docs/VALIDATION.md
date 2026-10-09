# ScreenQR 0.2.0 validation — 9 October 2026

## Checks completed

- Swift production compilation for arm64 and x86_64. Universal binary confirmed with lipo. Minimum deployment target macOS 14.
- Staged ad-hoc signature integrity, plist, ZIP integrity, DMG creation and SHA-256. No Developer ID certificate available; no notarization claimed.
- Six Apple Vision checks: HTTPS, Cyrillic text, Wi-Fi, mailto, two QR codes, no QR.
- Production QRPolicy: 12 permitted/rejected URL cases and five geometry cases, including reversed drags, Retina scaling, screen edges and too-small/outside selections.
- Screen Recording previously reset and regranted with explicit user approval. Current 0.2.0 successfully captured the screen without another permission reset.
- Live screen selection recognized https://example.com/screenqr-test. Own welcome/settings/result windows excluded from frozen capture.
- Image file with two QR codes produced two independent result cards. List alignment checked visually and corrected.
- Onboarding and settings inspected in native UI. Recognition remains the primary action; keyboard shortcut is optional, off by default in new installations.
- Earlier 0.1.2 desktop checks: default browser routing to Chrome, Copy confirmation, Escape cancellation, no-QR retry, shortcut recording/persistence, compact domain and full address disclosure. Retesting after changes is recorded separately below.
- Static site validation: 12 Russian/English pages, unique titles, one H1, descriptions, self canonicals, reciprocal hreflang, actual JSON-LD, internal assets/links, matching sitemap, 404 and total asset budget below 600 KB. No externally loaded fonts or analytics.

## Limits and remaining hardware checks

Physical global keyboard activation from a different app remains unverified; the user requested clarification about the shortcut rather than confirming activation. Targeted synthetic keyboard input is not equivalent to that hardware check. Automated checks and universal packaging also passed on the macos-15-intel CI runner. Interactive UI has not been tested on an Intel Mac. Additional macOS versions, different monitor scales, fullscreen/Spaces/Stage Manager and login startup require real-device checks. Clipboard/drop and image orientation need integration checks on representative images. Accessibility has native controls and labels but full VoiceOver testing is outstanding.

The app takes temporary screenshots of connected displays before selection. QR recognition is limited to the selected area; the OS screen permission is broader. No screenshot files or history are written. Links are not scanned for website reputation.

## Critical shortcut correction

The original prototype accidentally used Command–Shift–Q, the macOS logout shortcut. It was removed. Fresh installs have no hotkey; previous Q assignments reset. Q and power/function keycodes >=120 are rejected, and enabled macOS symbolic hotkeys are checked. Failed registration now disables the assignment. Old 0.1.0/0.1.1 archives must not be used or published.

## Final local UI checks

The normal Finder launch of the final 0.2.0 build captured the screen successfully. Reverse-direction selection recognized the test QR. A reverse selection on an empty area showed the no-QR explanation and retry. Copy displayed confirmation; the single-result card was visually checked with its measured content size. English onboarding and the permission-denied explanation were inspected using --english. Direct executable launch from a terminal lacked screen access; no additional permission was granted. This does not invalidate the successful normal bundled launch.

The site was checked in the in-app browser at actual widths 853 and 360 pixels: no horizontal overflow. English/Russian navigation, a PDF guide, demo toggle and demo copy feedback were checked.

## Release status

Published prerelease: https://github.com/kunilingvistador/ScreenQR/releases/tag/v0.2.0-beta

Published website: https://kunilingvistador.github.io/ScreenQR/ (Russian and English). All 12 canonical pages returned HTTP 200; an intentionally missing page returned 404. ProfileDock Russian and English homepages contain the published ScreenQR link; ScreenQR links back to ProfileDock.

Mac checks CI run 37949226323 passed on macos-15 and macos-15-intel. Website deployment run 37949226061 succeeded after enabling Pages. ProfileDock related-site deployment run 37950040079 succeeded.

Downloaded public ZIP and DMG matched published SHA-256 checksums. ZIP integrity, extracted app signature integrity, both binary architectures and DMG verification passed independently of local build files.

Public distribution remains explicitly beta until Developer ID signing/notarization and wider hardware QA.
