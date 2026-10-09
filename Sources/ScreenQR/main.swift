import AppKit
import Vision
import Carbon
import ScreenCaptureKit
import UniformTypeIdentifiers
import ServiceManagement
import ImageIO

struct ResultItem { let text: String; let image: NSImage }
final class App: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var status: NSStatusItem!
    var panels: [NSWindow] = []
    var resultWindow: NSWindow?
    var settingsWindow: NSWindow?
    var welcomeWindow: NSWindow?
    let shortcutSummary = NSTextField(labelWithString: "")
    var hotKey: EventHotKeyRef?
    var handler: EventHandlerRef?
    var lastSelectionPoint: NSPoint?
    var keyMonitor: Any?
    var shortcutMonitor: Any?
    var capturing = false
    var busy = false
    var results: [ResultItem] = []
    let compact = NSButton(checkboxWithTitle: L("Компактная карточка результата"), target: nil, action: nil)
    var progressWindow: NSWindow?
    var decodeGeneration = 0
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let menu = NSMenu(); let root = NSMenuItem(); menu.addItem(root); root.submenu = NSMenu()
        for (title, action, key) in [(L("Сканировать экран"), #selector(scan), ""), (L("Настройки…"), #selector(settings), ","), (L("Из буфера обмена"), #selector(paste), ""), (L("Завершить ScreenQR"), #selector(quit), "q")] { let item = NSMenuItem(title: L(title), action: action, keyEquivalent: key); item.target = self; root.submenu?.addItem(item) }; NSApp.mainMenu = menu
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        status.button?.image = NSImage(systemSymbolName: "qrcode.viewfinder", accessibilityDescription: L("Сканировать QR-код"))
        status.button?.toolTip = L("Сканировать QR-код")
        status.button?.target = self; status.button?.action = #selector(statusClick)
        status.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        registerHotKey()
        shortcutMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.keyMonitor == nil, !event.isARepeat, let code = UserDefaults.standard.object(forKey: "keyCode") as? Int, code >= 0, code == Int(event.keyCode) else { return event }
            let flags = event.modifierFlags.intersection([.command, .option, .shift, .control])
            var modifiers = 0
            if flags.contains(.command) { modifiers |= cmdKey }; if flags.contains(.control) { modifiers |= controlKey }; if flags.contains(.option) { modifiers |= optionKey }; if flags.contains(.shift) { modifiers |= shiftKey }
            guard modifiers == UserDefaults.standard.object(forKey: "keyModifiers") as? Int else { return event }
            self.scan(); return nil
        }
        if CommandLine.arguments.contains("--demo") { showWelcome() }
        else if !UserDefaults.standard.bool(forKey: "completedFirstScan") { showWelcome() }
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { if let window = resultWindow { window.makeKeyAndOrderFront(nil) } else if !flag { showWelcome() }; return true }
    @objc func statusClick() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            let menu = NSMenu()
            for (title, action) in [(L("Сканировать экран"), #selector(scan)), (L("Из буфера обмена"), #selector(paste)), (L("Открыть изображение…"), #selector(openFile)), (L("Настройки…"), #selector(settings)), (L("Выход"), #selector(quit))] {
                let item = NSMenuItem(title: L(title), action: action, keyEquivalent: ""); item.target = self; menu.addItem(item)
            }
            status.menu = menu; status.button?.performClick(nil); status.menu = nil
        } else { scan() }
    }
    func registerHotKey() {
        if let hotKey { UnregisterEventHotKey(hotKey) }; hotKey = nil
        if handler == nil {
            var type = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            InstallEventHandler(GetEventDispatcherTarget(), { _, event, context in
                guard let event, let context else { return OSStatus(eventNotHandledErr) }
                var identifier = EventHotKeyID()
                guard GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &identifier) == noErr, identifier.signature == 0x53515231 else { return OSStatus(eventNotHandledErr) }
                let app = Unmanaged<App>.fromOpaque(context).takeUnretainedValue()
                DispatchQueue.main.async { app.scan() }; return noErr
            }, 1, &type, Unmanaged.passUnretained(self).toOpaque(), &handler)
        }
        let code = UserDefaults.standard.object(forKey: "keyCode") as? Int ?? -1
        if code == Int(kVK_ANSI_Q) || code >= 120 { UserDefaults.standard.set(-1, forKey: "keyCode"); return }
        if code < 0 { return }
        let result = RegisterEventHotKey(UInt32(code), UInt32(UserDefaults.standard.object(forKey: "keyModifiers") as? Int ?? Int(cmdKey | optionKey | shiftKey)), EventHotKeyID(signature: 0x53515231, id: 1), GetEventDispatcherTarget(), UInt32(kEventHotKeyExclusive), &hotKey)
        if result != noErr { UserDefaults.standard.set(-1, forKey: "keyCode"); UserDefaults.standard.removeObject(forKey: "shortcutLabel"); shortcutSummary.stringValue = L("Не назначена"); message(L("Сочетание занято"), L("Выберите другое сочетание в настройках. Сканирование по значку продолжает работать.")) }
    }
    func isReserved(code: UInt32, modifiers: UInt32) -> Bool {
        var values: Unmanaged<CFArray>?
        if CopySymbolicHotKeys(&values) == noErr, let array = values?.takeRetainedValue() as? [[String: Any]] {
            return array.contains { ($0[kHISymbolicHotKeyEnabled as String] as? NSNumber)?.boolValue == true && ($0[kHISymbolicHotKeyCode as String] as? NSNumber)?.uint32Value == code && ($0[kHISymbolicHotKeyModifiers as String] as? NSNumber)?.uint32Value == modifiers }
        }; return false
    }
    @objc func quit() { NSApp.terminate(nil) }
    func message(_ title: String, _ detail: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert(); alert.messageText = L(title); alert.informativeText = L(detail); alert.runModal()
    }
    func showWelcome() {
        UserDefaults.standard.set(true, forKey: "welcomed")
        welcomeWindow?.close()
        let window = makeWindow(L("ScreenQR — QR-коды с экрана"), width: 490, height: 420)
        let stack = makeStack(window)
        let icon = NSImageView(); icon.image = NSImage(named: NSImage.applicationIconName); icon.imageScaling = .scaleProportionallyUpOrDown; icon.widthAnchor.constraint(equalToConstant: 64).isActive = true; icon.heightAnchor.constraint(equalToConstant: 64).isActive = true; stack.addArrangedSubview(icon)
        addLabel(L("QR уже на компьютере?"), to: stack, size: 23)
        addLabel(L("Нажмите значок QR в строке меню, выделите код и откройте ссылку. Своё сочетание клавиш можно назначить в настройках. Правый клик по значку открывает остальные действия."), to: stack)
        addLabel(L("Распознавание работает на Mac. Изображения не отправляются в интернет и не сохраняются. Доступ к экрану понадобится только для сканирования экрана."), to: stack)
        addButton(L("Сканировать QR на экране"), #selector(scan), to: stack)
        addButton(L("Настройки и горячая клавиша…"), #selector(settings), to: stack)
        addLabel(L("Дополнительные способы — картинка и буфер обмена — доступны по правому клику на значке."), to: stack)
        welcomeWindow = window; window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
    }
    @objc func scan() {
        guard !capturing && !busy else { return }
        capturing = true; resultWindow?.orderOut(nil); welcomeWindow?.orderOut(nil); settingsWindow?.orderOut(nil)
        Task { @MainActor in
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                var snapshots: [(NSScreen, CGImage)] = []
                for screen in NSScreen.screens {
                    guard let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? UInt32,
                          let display = content.displays.first(where: { $0.displayID == id }) else { continue }
                    let ownApps = content.applications.filter { $0.processID == ProcessInfo.processInfo.processIdentifier }
                    let filter = SCContentFilter(display: display, excludingApplications: ownApps, exceptingWindows: [])
                    let config = SCStreamConfiguration(); config.width = Int(screen.frame.width * screen.backingScaleFactor); config.height = Int(screen.frame.height * screen.backingScaleFactor); config.showsCursor = false; config.captureResolution = .best; config.ignoreShadowsSingleWindow = true
                    let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
                    snapshots.append((screen, image))
                }
                if snapshots.isEmpty { throw NSError(domain: "ScreenQR", code: 1) }
                let activePoint = NSEvent.mouseLocation
                var activePanel: NSWindow?
                for (screen, image) in snapshots {
                    let panel = CaptureWindow(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
                    panel.level = .screenSaver; panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]; panel.isReleasedWhenClosed = false
                    panel.setFrame(screen.frame, display: false)
                    panel.contentView = SelectionView(app: self, image: image, frame: NSRect(origin: .zero, size: screen.frame.size))
                    self.panels.append(panel); panel.orderFrontRegardless(); if screen.frame.contains(activePoint) { activePanel = panel }
                }
                (activePanel ?? self.panels.first)?.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            } catch {
                cancelCapture()
                NSApp.activate(ignoringOtherApps: true)
                let alert = NSAlert(); alert.messageText = L("Не удалось получить снимок экрана")
                alert.informativeText = L("Разрешите ScreenQR запись экрана в Системных настройках. Приложение распознаёт QR локально, не записывает звук и не сохраняет снимки. После выдачи доступа перезапустите ScreenQR.")
                alert.addButton(withTitle: L("Открыть настройки доступа")); alert.addButton(withTitle: L("Позже"))
                if alert.runModal() == .alertFirstButtonReturn, let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") { NSWorkspace.shared.open(url) }
            }
        }
    }
    func cancelCapture() { for panel in panels { panel.orderOut(nil) }; panels.removeAll(); capturing = false }
    func selected(_ image: CGImage) { UserDefaults.standard.set(true, forKey: "completedFirstScan"); lastSelectionPoint = NSEvent.mouseLocation; cancelCapture(); decode(image) }
    @objc func paste() {
        guard !capturing && !busy else { return }; lastSelectionPoint = nil
        guard let image = NSImage(pasteboard: .general), let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { message(L("В буфере нет изображения"), L("Скопируйте картинку с QR-кодом или выделите код прямо на экране.")); return }
        decode(cg)
    }
    @objc func openFile() {
        guard !capturing && !busy else { return }; lastSelectionPoint = nil
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSOpenPanel(); panel.allowedContentTypes = [.image]; panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url { load(url) }
    }
    func load(_ url: URL) {
        guard !capturing && !busy else { return }; lastSelectionPoint = nil
        guard url.isFileURL else { message(L("Не удалось прочитать изображение"), L("Попробуйте файл PNG, JPEG или HEIC.")); return }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceThumbnailMaxPixelSize: 8192, kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary) else {
            message(L("Не удалось прочитать изображение"), L("Попробуйте файл PNG, JPEG или HEIC.")); return
        }
        decode(image)
    }
    func showProgress() {
        let window = makeWindow(L("Распознаём QR…"), width: 340, height: 150)
        let stack = makeStack(window)
        let spinner = NSProgressIndicator(); spinner.style = .spinning; spinner.startAnimation(nil); stack.addArrangedSubview(spinner)
        addLabel(L("Проверяем выделенную область на вашем Mac…"), to: stack)
        addButton(L("Отмена"), #selector(cancelDecode), to: stack)
        progressWindow = window; window.makeKeyAndOrderFront(nil)
    }
    @objc func cancelDecode() { decodeGeneration += 1; busy = false; progressWindow?.close(); progressWindow = nil; status.button?.toolTip = L("Сканировать QR-код") }
    func decode(_ image: CGImage) {
        guard !busy && !capturing else { return }; busy = true
        decodeGeneration += 1; let generation = decodeGeneration
        showProgress()
        status.button?.toolTip = L("Распознаём QR…")
        DispatchQueue.global(qos: .userInitiated).async {
            let request = VNDetectBarcodesRequest(); request.symbologies = [.qr]
            do {
                try VNImageRequestHandler(cgImage: image).perform([request])
                let items = (request.results ?? []).compactMap { observation -> ResultItem? in
                    guard let text = observation.payloadStringValue else { return nil }
                    let box = observation.boundingBox
                    let rect = CGRect(x: box.minX * CGFloat(image.width), y: (1 - box.maxY) * CGFloat(image.height), width: box.width * CGFloat(image.width), height: box.height * CGFloat(image.height)).integral
                    return ResultItem(text: text, image: NSImage(cgImage: image.cropping(to: rect) ?? image, size: NSSize(width: 70, height: 70)))
                }
                DispatchQueue.main.async {
                    guard generation == self.decodeGeneration else { return }
                    self.progressWindow?.delegate = nil; self.progressWindow?.close(); self.progressWindow = nil
                    self.busy = false; self.status.button?.toolTip = L("Сканировать QR-код")
                    if items.isEmpty { self.showEmpty() } else { self.results = items; self.showResults() }
                }
            } catch { DispatchQueue.main.async { guard generation == self.decodeGeneration else { return }; self.cancelDecode(); self.message(L("Не удалось распознать QR"), L("Попробуйте другое изображение или выделите область снова.")) } }
        }
    }
    func payloadTitle(_ text: String) -> String {
        if text.hasPrefix("WIFI:") { return L("Данные сети Wi-Fi") }
        if text.uppercased().hasPrefix("BEGIN:VCARD") { return L("Контакт") }
        if text.lowercased().hasPrefix("mailto:") { return L("Электронная почта") }
        if text.lowercased().hasPrefix("tel:") { return L("Телефон") }
        return L("Текст или данные QR")
    }
    func webURL(_ text: String) -> URL? { QRPolicy.webURL(text) }
    func showEmpty() {
        let window = makeWindow(L("QR-код не найден"), width: 410, height: 240); let stack = makeStack(window)
        addLabel(L("Попробуйте увеличить изображение и выделить код целиком, оставив немного пространства вокруг."), to: stack)
        addButton(L("Выделить снова"), #selector(scan), to: stack); addButton(L("Закрыть"), #selector(closeResult), to: stack)
        present(window)
    }
    func showResults(expanded: Bool = false) {
        let isCompact = !expanded && UserDefaults.standard.bool(forKey: "compact")
        let window = makeWindow(results.count > 1 ? "\(L("Найдено QR-кодов")): \(results.count)" : L("QR распознан"), width: 460, height: min(650, CGFloat(results.count * (isCompact ? 160 : 250) + 100)))
        let scroll = NSScrollView(); scroll.hasVerticalScroller = true; scroll.translatesAutoresizingMaskIntoConstraints = false
        window.contentView!.addSubview(scroll)
        NSLayoutConstraint.activate([scroll.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor, constant: 20), scroll.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor, constant: -20), scroll.topAnchor.constraint(equalTo: window.contentView!.topAnchor, constant: 16), scroll.bottomAnchor.constraint(equalTo: window.contentView!.bottomAnchor, constant: -16)])
        let stack = ResultStack(); stack.orientation = .vertical; stack.alignment = .leading; stack.spacing = 12; stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.documentView = stack; stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -16).isActive = true
        for (index, item) in results.enumerated() {
            let url = webURL(item.text)
            addLabel(url?.host ?? payloadTitle(item.text), to: stack, size: 18)
            if !isCompact || url == nil {
                let image = NSImageView(); image.image = item.image; image.imageScaling = .scaleProportionallyUpOrDown; image.setFrameSize(NSSize(width: 70, height: 70)); image.heightAnchor.constraint(equalToConstant: 70).isActive = true; image.widthAnchor.constraint(equalToConstant: 70).isActive = true; stack.addArrangedSubview(image)
                addLabel(item.text, to: stack)
            } else { addButton(L("Показать полный адрес"), #selector(expand), to: stack) }
            let row = NSStackView(); row.spacing = 10
            if url != nil { let button = NSButton(title: L("Открыть в браузере"), target: self, action: #selector(openResult)); button.tag = index; row.addArrangedSubview(button) }
            let copy = NSButton(title: L("Скопировать"), target: self, action: #selector(copyResult)); copy.tag = index; row.addArrangedSubview(copy)
            stack.addArrangedSubview(row)
            let line = NSBox(); line.boxType = .separator; stack.addArrangedSubview(line)
        }
        window.minSize = NSSize(width: 460, height: 180)
        window.contentView?.layoutSubtreeIfNeeded()
        let available = (NSScreen.main?.visibleFrame.height ?? 800) - 90
        window.setContentSize(NSSize(width: 460, height: max(180, min(650, available, stack.fittingSize.height + 40))))
        present(window)
    }
    @objc func closeResult() { resultWindow?.close() }
    @objc func expand() { showResults(expanded: true) }
    @objc func openResult(_ sender: NSButton) { guard results.indices.contains(sender.tag) else { return }; if let url = webURL(results[sender.tag].text), !NSWorkspace.shared.open(url) { message(L("Не удалось открыть ссылку"), L("Скопируйте адрес и вставьте его в браузер.")) } }
    @objc func copyResult(_ sender: NSButton) { guard results.indices.contains(sender.tag) else { return }; NSPasteboard.general.clearContents(); NSPasteboard.general.setString(results[sender.tag].text, forType: .string); sender.title = L("Скопировано ✓") }
    @objc func settings() {
        settingsWindow?.close()
        let window = makeWindow(L("Настройки ScreenQR"), width: 430, height: 490); let stack = makeStack(window)
        compact.state = UserDefaults.standard.bool(forKey: "compact") ? .on : .off; compact.target = self; compact.action = #selector(saveCompact); stack.addArrangedSubview(compact)
        addLabel(L("Горячая клавиша"), to: stack)
        addLabel(L("Минимум два модификатора, включая ⌘ или ⌃. Esc — отмена записи."), to: stack)
        shortcutSummary.stringValue = UserDefaults.standard.string(forKey: "shortcutLabel") ?? L("Не назначена")
        stack.addArrangedSubview(shortcutSummary)
        addButton(L("Назначить своё сочетание…"), #selector(recordShortcut), to: stack)
        addButton(L("Отключить сочетание"), #selector(disableShortcut), to: stack)
        let login = NSButton(checkboxWithTitle: L("Запускать при входе в систему"), target: self, action: #selector(toggleLogin)); login.state = SMAppService.mainApp.status == .enabled ? .on : .off; stack.addArrangedSubview(login)
        addLabel(L("Снимки и результаты не сохраняются на диск. Ссылки открываются только по вашему нажатию."), to: stack)
        addButton(L("Открыть изображение / перетащить файл"), #selector(openFile), to: stack); stack.addArrangedSubview(DropView(app: self))
        settingsWindow = window; window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
    }
    @objc func recordShortcut(_ sender: NSButton) {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        sender.title = L("Нажмите сочетание · Esc — отмена")
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self, weak sender] event in
            guard let self else { return event }
            if event.keyCode == 53 { if let monitor = self.keyMonitor { NSEvent.removeMonitor(monitor) }; self.keyMonitor = nil; sender?.title = L("Записать своё сочетание…"); return nil }
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if event.keyCode == UInt16(kVK_ANSI_Q) || event.keyCode >= 120 { sender?.title = L("Это сочетание недоступно. Выберите другое"); return nil }
            guard flags.contains(.command) || flags.contains(.control), flags.intersection([.command, .control, .option, .shift]).rawValue.nonzeroBitCount >= 2 else { return nil }
            var modifiers = 0
            if flags.contains(.command) { modifiers |= cmdKey }; if flags.contains(.control) { modifiers |= controlKey }; if flags.contains(.option) { modifiers |= optionKey }; if flags.contains(.shift) { modifiers |= shiftKey }
            guard !self.isReserved(code: UInt32(event.keyCode), modifiers: UInt32(modifiers)) else { sender?.title = L("Занято системой. Выберите другое сочетание"); return nil }
            UserDefaults.standard.set(Int(event.keyCode), forKey: "keyCode"); UserDefaults.standard.set(modifiers, forKey: "keyModifiers")
            if let monitor = self.keyMonitor { NSEvent.removeMonitor(monitor) }; self.keyMonitor = nil
            let label = (flags.contains(.control) ? "⌃" : "") + (flags.contains(.option) ? "⌥" : "") + (flags.contains(.shift) ? "⇧" : "") + (flags.contains(.command) ? "⌘" : "") + (event.charactersIgnoringModifiers?.uppercased() ?? L("клавиша"))
            UserDefaults.standard.set(label, forKey: "shortcutLabel"); self.shortcutSummary.stringValue = label
            sender?.title = L("Назначить другое сочетание…")
            self.registerHotKey(); return nil
        }
    }
    @objc func toggleLogin(_ sender: NSButton) {
        do { if sender.state == .on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() } }
        catch { sender.state = SMAppService.mainApp.status == .enabled ? .on : .off; message(L("Не удалось изменить автозапуск"), L("Переместите приложение в Applications и проверьте Системные настройки → Основные → Объекты входа.")) }
    }
    @objc func saveCompact() { UserDefaults.standard.set(compact.state == .on, forKey: "compact") }
    @objc func disableShortcut() { UserDefaults.standard.set(-1, forKey: "keyCode"); UserDefaults.standard.set(L("Не назначена"), forKey: "shortcutLabel"); shortcutSummary.stringValue = L("Не назначена"); registerHotKey() }
    func makeWindow(_ title: String, width: CGFloat, height: CGFloat) -> NSWindow {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: width, height: height), styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.title = L(title); window.minSize = window.frame.size; window.center(); window.isReleasedWhenClosed = false; window.delegate = self; return window
    }
    func makeStack(_ window: NSWindow) -> NSStackView {
        let stack = NSStackView(); stack.orientation = .vertical; stack.alignment = .leading; stack.spacing = 14; stack.translatesAutoresizingMaskIntoConstraints = false; window.contentView!.addSubview(stack)
        NSLayoutConstraint.activate([stack.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor, constant: 22), stack.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor, constant: -22), stack.topAnchor.constraint(equalTo: window.contentView!.topAnchor, constant: 22)])
        return stack
    }
    func addLabel(_ text: String, to stack: NSStackView, size: CGFloat = 13) { let label = NSTextField(wrappingLabelWithString: text); label.font = .systemFont(ofSize: size, weight: size > 13 ? .semibold : .regular); label.isSelectable = true; label.lineBreakMode = text.lowercased().hasPrefix("http") ? .byCharWrapping : .byWordWrapping; label.widthAnchor.constraint(lessThanOrEqualToConstant: 400).isActive = true; stack.addArrangedSubview(label) }
    func addButton(_ title: String, _ action: Selector, to stack: NSStackView) { let button = NSButton(title: L(title), target: self, action: action); button.bezelStyle = .rounded; button.controlSize = .large; if action == #selector(scan) { button.bezelColor = .systemBlue }; stack.addArrangedSubview(button) }
    func present(_ window: NSWindow) { if let point = lastSelectionPoint, let screen = NSScreen.screens.first(where: { $0.frame.contains(point) }) { let area = screen.visibleFrame; window.setFrameOrigin(NSPoint(x: max(area.minX, min(point.x + 12, area.maxX - window.frame.width)), y: max(area.minY, min(point.y - window.frame.height, area.maxY - window.frame.height)))); lastSelectionPoint = nil }; resultWindow?.delegate = nil; resultWindow?.close(); resultWindow = window; window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true) }
    func windowWillClose(_ notification: Notification) { if (notification.object as? NSWindow) === progressWindow && busy { cancelDecode() }; if (notification.object as? NSWindow) === settingsWindow, let keyMonitor { NSEvent.removeMonitor(keyMonitor); self.keyMonitor = nil }; if (notification.object as? NSWindow) === resultWindow { results.removeAll(); resultWindow = nil } }
}
final class ResultStack: NSStackView { override var isFlipped: Bool { true } }
final class CaptureWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
final class SelectionView: NSView {
    unowned let app: App; let image: CGImage; var start: NSPoint?; var selection = NSRect.zero
    init(app: App, image: CGImage, frame: NSRect) { self.app = app; self.image = image; super.init(frame: frame) }
    required init?(coder: NSCoder) { fatalError() }
    override var acceptsFirstResponder: Bool { true }
    override func viewDidMoveToWindow() { window?.makeFirstResponder(self) }
    override func resetCursorRects() { addCursorRect(bounds, cursor: .crosshair) }
    override func draw(_ dirtyRect: NSRect) {
        NSImage(cgImage: image, size: bounds.size).draw(in: bounds)
        NSColor.black.withAlphaComponent(0.3).setFill(); let shade = NSBezierPath(rect: bounds); shade.appendRect(selection); shade.windingRule = .evenOdd; shade.fill()
        NSColor.white.setStroke(); NSBezierPath(rect: selection).stroke()
        let hint = L("Выделите QR-код · Esc — отмена") as NSString
        hint.draw(at: NSPoint(x: 24, y: bounds.height - 45), withAttributes: [.foregroundColor: NSColor.white, .font: NSFont.systemFont(ofSize: 17, weight: .semibold)])
    }
    override func mouseDown(with event: NSEvent) { start = convert(event.locationInWindow, from: nil) }
    override func mouseDragged(with event: NSEvent) { guard let start else { return }; let end = convert(event.locationInWindow, from: nil); selection = NSRect(x: min(start.x, end.x), y: min(start.y, end.y), width: abs(end.x - start.x), height: abs(end.y - start.y)).intersection(bounds); needsDisplay = true }
    override func mouseUp(with event: NSEvent) {
        mouseDragged(with: event); guard selection.width > 4, selection.height > 4 else { return }
        if let rect = QRPolicy.cropRect(selection: selection, bounds: bounds, width: image.width, height: image.height), let crop = image.cropping(to: rect) { app.selected(crop) }
    }
    override func rightMouseDown(with event: NSEvent) { app.cancelCapture() }
    override func keyDown(with event: NSEvent) { if event.keyCode == 53 { app.cancelCapture() } }
}
final class DropView: NSView {
    unowned let app: App
    init(app: App) { self.app = app; super.init(frame: NSRect(x: 0, y: 0, width: 380, height: 45)); registerForDraggedTypes([.fileURL, .tiff, .png]); heightAnchor.constraint(equalToConstant: 45).isActive = true; widthAnchor.constraint(equalToConstant: 380).isActive = true }
    required init?(coder: NSCoder) { fatalError() }
    override func draw(_ rect: NSRect) { NSColor.controlBackgroundColor.setFill(); NSBezierPath(roundedRect: bounds, xRadius: 8, yRadius: 8).fill(); (L("Перетащите сюда изображение с QR") as NSString).draw(at: NSPoint(x: 16, y: 14), withAttributes: [.foregroundColor: NSColor.secondaryLabelColor, .font: NSFont.systemFont(ofSize: 13)]) }
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation { .copy }
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let board = sender.draggingPasteboard
        if let urls = board.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], let url = urls.first { app.load(url); return true }
        if let image = NSImage(pasteboard: board), let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) { app.decode(cg); return true }; return false
    }
}
let application = NSApplication.shared
let delegate = App()
application.delegate = delegate
application.run()
