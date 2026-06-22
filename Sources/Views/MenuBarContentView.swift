import SwiftUI

// MARK: - Panel Root (Arrow + Body)

enum MenuBarPopoverMetrics {
    static let shadowPadding: CGFloat = 80
    static let screenEdgePadding: CGFloat = 12
    static let menuGap: CGFloat = 6
}

struct MenuBarPanelView: View {
    var dismissPopover: @MainActor () -> Void
    @State private var isVisible = false

    private let panelRadius: CGFloat = 12
    private let shadowColor = Color(red: 9 / 255, green: 9 / 255, blue: 11 / 255)

    var body: some View {
        MenuBarContentView(dismissPopover: dismissPopover)
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: panelRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: panelRadius, style: .continuous)
                    .strokeBorder(shadowColor.opacity(0.10), lineWidth: 1)
            )
            .shadow(color: shadowColor.opacity(0.10), radius: 20, y: 20)
            .shadow(color: .black.opacity(0.06), radius: 4, y: 8)
            .padding(MenuBarPopoverMetrics.shadowPadding)
        .scaleEffect(isVisible ? 1 : 0.92, anchor: .top)
        .opacity(isVisible ? 1 : 0)
        .blur(radius: isVisible ? 0 : 4)
        .onAppear {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Panel Content

struct MenuBarContentView: View {
    var dismissPopover: @MainActor () -> Void

    var body: some View {
        VStack(spacing: MenuRowStyle.gap) {
            TrayRowButton(title: "Region or Window", iconAsset: "MenuIconRegion", shortcut: "\u{2318}4") {
                dismissAndRun(.region)
            }

            TrayRowButton(title: "Entire Screen", iconAsset: "MenuIconScreen", shortcut: "\u{2318}3") {
                dismissAndRun(.fullscreen)
            }

            TrayRowButton(title: "Capture Text - OCR", iconAsset: "MenuIconOCR", shortcut: "\u{2318}O") {
                dismissAndRun(.ocr)
            }

            TrayRowMenu(title: "Record", iconAsset: "MenuIconRecord", shortcut: "\u{2318}\u{21E7}2", menuItems: [
                TrayMenuItem(title: "Full Screen", icon: "desktopcomputer") {
                    nonisolated(unsafe) let screen = originScreen
                    dismissPopover()
                    Task.detached {
                        try? await Task.sleep(nanoseconds: 200_000_000)
                        await startRecording(mode: .fullScreen, on: screen)
                    }
                },
                TrayMenuItem(title: "Area", icon: "rectangle.dashed") {
                    nonisolated(unsafe) let screen = originScreen
                    dismissPopover()
                    Task.detached {
                        try? await Task.sleep(nanoseconds: 200_000_000)
                        await startRecording(mode: .area, on: screen)
                    }
                },
            ])

            MenuDivider()

            TrayRowMenu(title: "Recents", iconAsset: "MenuIconRecents", background: nil, trailingChevronAsset: "MenuIconChevron", menuItems: recentMenuItems())

            if PinnedScreenshotController.shared.hasPinnedWindows {
                TrayRowButton(title: "Unpin All", systemIcon: "pin.slash") {
                    PinnedScreenshotController.shared.unpinAll()
                    dismissPopover()
                }
            }

            TrayRowButton(title: "Settings", iconAsset: "MenuIconSettings", shortcut: "\u{2318},", background: nil) {
                openSettings()
            }

            TrayRowButton(title: "Quit SupremeShot", shortcut: "\u{2318}Q", background: nil) {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(MenuRowStyle.containerPadding)
        .frame(width: 292)
    }

    // MARK: - History

    private var recentScreenshots: [CaptureRecord] {
        HistoryStore.shared.records.filter { $0.kind == .screenshot }
    }

    private var recentRecordings: [CaptureRecord] {
        HistoryStore.shared.records.filter { $0.kind == .recording }
    }

    // MARK: - Actions

    private var originScreen: NSScreen? {
        MenuBarPopoverController.shared.originScreen
    }

    private func dismissAndRun(_ action: ShortcutService.Action) {
        nonisolated(unsafe) let screen = originScreen
        dismissPopover()
        Task.detached {
            try? await Task.sleep(nanoseconds: 200_000_000)
            await CaptureOrchestrator.shared.performCapture(action, on: screen)
        }
    }

    private func recentMenuItems() -> [TrayMenuItem] {
        var items: [TrayMenuItem] = []

        var screenshotItems: [TrayMenuItem] = []
        if recentScreenshots.isEmpty {
            screenshotItems.append(TrayMenuItem(title: "No screenshots yet", icon: "photo", action: {}, isDisabled: true))
        } else {
            for record in recentScreenshots.prefix(8) {
                screenshotItems.append(TrayMenuItem(title: record.filename, icon: "photo") { [record] in
                    let screen = originScreen
                    dismissPopover()
                    let url = HistoryStore.shared.displayURLForRecord(record)
                    PreviewOverlay.shared.show(url: url, on: screen)
                })
            }
            screenshotItems.append(.separator())
            screenshotItems.append(TrayMenuItem(title: "Clear Screenshots", icon: "trash", action: {
                HistoryStore.shared.records
                    .filter { $0.kind == .screenshot }
                    .forEach { HistoryStore.shared.deleteRecord($0) }
            }, isDestructive: true))
        }
        items.append(TrayMenuItem(title: "Screenshots", icon: "photo.on.rectangle", action: {}, submenu: screenshotItems))

        var recordingItems: [TrayMenuItem] = []
        if recentRecordings.isEmpty {
            recordingItems.append(TrayMenuItem(title: "No recordings yet", icon: "video", action: {}, isDisabled: true))
        } else {
            for record in recentRecordings.prefix(8) {
                recordingItems.append(TrayMenuItem(title: record.filename, icon: "video") { [record] in
                    let screen = originScreen
                    dismissPopover()
                    let url = HistoryStore.shared.displayURLForRecord(record)
                    PreviewOverlay.shared.show(url: url, on: screen)
                })
            }
            recordingItems.append(.separator())
            recordingItems.append(TrayMenuItem(title: "Clear Recordings", icon: "trash", action: {
                HistoryStore.shared.records
                    .filter { $0.kind == .recording }
                    .forEach { HistoryStore.shared.deleteRecord($0) }
            }, isDestructive: true))
        }
        items.append(TrayMenuItem(title: "Recordings", icon: "video.circle", action: {}, submenu: recordingItems))

        return items
    }

    private func openSettings() {
        let screen = originScreen
        dismissPopover()
        SettingsWindowController.shared.open(on: screen)
    }

    private enum RecordingMode {
        case fullScreen, area
    }

    @MainActor
    private func startRecording(mode: RecordingMode = .fullScreen, on screen: NSScreen? = nil) async {
        do {
            let started: Bool
            switch mode {
            case .fullScreen:
                started = try await ScreenRecordingManager.shared.startFullScreenRecording()
            case .area:
                started = try await ScreenRecordingManager.shared.startAreaRecording()
            }
            if started {
                RecordingStatusBarController.shared.show(on: screen)
            }
        } catch {
            print("Recording failed: \(error.localizedDescription)")
        }
    }

}

// MARK: - Row Style

private enum MenuRowStyle {
    static let containerPadding: CGFloat = 8
    static let gap: CGFloat = 8
    static let rowHeight: CGFloat = 40
    static let cornerRadius: CGFloat = 10
    static let iconSize: CGFloat = 24
    static let horizontalPadding: CGFloat = 10
    static let iconTextGap: CGFloat = 10
    static let textSize: CGFloat = 14
    static let textColor = Color(red: 32 / 255, green: 32 / 255, blue: 32 / 255)
    static let shortcutOpacity: Double = 0.40
    static let background = Color(red: 231 / 255, green: 231 / 255, blue: 237 / 255)
    static let hoverBackground = Color(red: 185 / 255, green: 185 / 255, blue: 190 / 255)
    static let nsBackground = NSColor(red: 231 / 255, green: 231 / 255, blue: 237 / 255, alpha: 1)
    static let nsHoverBackground = NSColor(red: 185 / 255, green: 185 / 255, blue: 190 / 255, alpha: 1)
    static let dividerHeight: CGFloat = 17
    static let chevronSize = CGSize(width: 12.5, height: 7)
}

private enum MenuIconSpec {
    static func glyphSize(for assetName: String) -> CGSize {
        switch assetName {
        case "MenuIconRegion":
            CGSize(width: 18, height: 18)
        case "MenuIconScreen":
            CGSize(width: 19.47, height: 17.33)
        case "MenuIconOCR":
            CGSize(width: 22, height: 20.29)
        case "MenuIconRecord":
            CGSize(width: 19.47, height: 16.67)
        case "MenuIconRecents", "MenuIconSettings", "MenuIconQuit":
            CGSize(width: 19.34, height: 19.34)
        case "MenuIconChevron":
            MenuRowStyle.chevronSize
        default:
            CGSize(width: MenuRowStyle.iconSize, height: MenuRowStyle.iconSize)
        }
    }
}

// MARK: - Row Button

struct TrayRowButton: View {
    let title: String
    var iconAsset: String? = nil
    var systemIcon: String? = nil
    var shortcut: String? = nil
    var background: Color? = MenuRowStyle.background
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: MenuRowStyle.iconTextGap) {
                rowIcon

                Text(title)
                    .font(.system(size: MenuRowStyle.textSize, weight: .medium))
                    .foregroundStyle(MenuRowStyle.textColor)
                    .lineLimit(1)

                Spacer(minLength: 8)

                if let shortcut {
                    Text(shortcut)
                        .font(.system(size: MenuRowStyle.textSize, weight: .medium))
                        .foregroundStyle(MenuRowStyle.textColor.opacity(MenuRowStyle.shortcutOpacity))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, MenuRowStyle.horizontalPadding)
            .frame(height: MenuRowStyle.rowHeight)
            .background(
                RoundedRectangle(cornerRadius: MenuRowStyle.cornerRadius, style: .continuous)
                    .fill(rowBackground)
            )
            .contentShape(RoundedRectangle(cornerRadius: MenuRowStyle.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var rowBackground: Color {
        guard let background else { return .clear }
        return isHovered ? MenuRowStyle.hoverBackground : background
    }

    @ViewBuilder
    private var rowIcon: some View {
        if let iconAsset {
            let glyphSize = MenuIconSpec.glyphSize(for: iconAsset)
            ZStack {
                Image(iconAsset)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(MenuRowStyle.textColor)
                    .frame(width: glyphSize.width, height: glyphSize.height)
            }
            .frame(width: MenuRowStyle.iconSize, height: MenuRowStyle.iconSize)
        } else if let systemIcon {
            Image(systemName: systemIcon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(MenuRowStyle.textColor)
                .frame(width: MenuRowStyle.iconSize, height: MenuRowStyle.iconSize)
        }
    }
}

// MARK: - Row Menu (dropdown matching row style via NSMenu)

struct TrayRowMenu: NSViewRepresentable {
    let title: String
    let iconAsset: String
    var shortcut: String? = nil
    var background: Color? = MenuRowStyle.background
    var trailingChevronAsset: String? = nil
    let menuItems: [TrayMenuItem]

    func makeNSView(context: Context) -> TrayRowMenuButton {
        let button = TrayRowMenuButton(
            title: title,
            iconAsset: iconAsset,
            shortcut: shortcut,
            backgroundColor: background == nil ? nil : NSColor(red: 231 / 255, green: 231 / 255, blue: 237 / 255, alpha: 1),
            trailingChevronAsset: trailingChevronAsset,
            menuItems: menuItems
        )
        return button
    }

    func updateNSView(_ nsView: TrayRowMenuButton, context: Context) {
        nsView.menuItems = menuItems
        nsView.shortcut = shortcut
        nsView.backgroundColor = background == nil ? nil : MenuRowStyle.nsBackground
        nsView.trailingChevronAssetName = trailingChevronAsset
    }
}

struct TrayMenuItem {
    let title: String
    let icon: String
    let action: () -> Void
    var isDestructive: Bool = false
    var isSeparator: Bool = false
    var isDisabled: Bool = false
    var submenu: [TrayMenuItem]? = nil

    static func separator() -> TrayMenuItem {
        TrayMenuItem(title: "", icon: "", action: {}, isSeparator: true)
    }
}

final class TrayRowMenuButton: NSView {
    var menuItems: [TrayMenuItem]
    var backgroundColor: NSColor? {
        didSet { needsDisplay = true }
    }
    var shortcut: String? {
        didSet { needsDisplay = true }
    }
    var trailingChevronAssetName: String? {
        didSet { needsDisplay = true }
    }
    private let titleText: String
    private let iconAssetName: String
    private var isHovered = false
    private var trackingArea: NSTrackingArea?

    init(title: String, iconAsset: String, shortcut: String?, backgroundColor: NSColor?, trailingChevronAsset: String?, menuItems: [TrayMenuItem]) {
        self.titleText = title
        self.iconAssetName = iconAsset
        self.shortcut = shortcut
        self.backgroundColor = backgroundColor
        self.trailingChevronAssetName = trailingChevronAsset
        self.menuItems = menuItems
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: MenuRowStyle.rowHeight)
    }

    override func updateTrackingAreas() {
        if let existing = trackingArea { removeTrackingArea(existing) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self)
        addTrackingArea(area)
        trackingArea = area
        super.updateTrackingAreas()
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        let menu = NSMenu()
        for item in menuItems {
            if item.isSeparator {
                menu.addItem(.separator())
                continue
            }
            if let submenuItems = item.submenu {
                let parentItem = NSMenuItem(title: item.title, action: nil, keyEquivalent: "")
                if let img = NSImage(systemSymbolName: item.icon, accessibilityDescription: nil) {
                    parentItem.image = img
                }
                let sub = NSMenu()
                for subItem in submenuItems {
                    if subItem.isSeparator {
                        sub.addItem(.separator())
                        continue
                    }
                    let mi = NSMenuItem(title: subItem.title, action: #selector(menuAction(_:)), keyEquivalent: "")
                    mi.target = self
                    mi.representedObject = subItem.action
                    if let img = NSImage(systemSymbolName: subItem.icon, accessibilityDescription: nil) {
                        mi.image = img
                    }
                    if subItem.isDestructive {
                        mi.attributedTitle = NSAttributedString(string: subItem.title, attributes: [.foregroundColor: NSColor.systemRed])
                    }
                    mi.isEnabled = !subItem.isDisabled
                    sub.addItem(mi)
                }
                parentItem.submenu = sub
                menu.addItem(parentItem)
            } else {
                let mi = NSMenuItem(title: item.title, action: #selector(menuAction(_:)), keyEquivalent: "")
                mi.target = self
                mi.representedObject = item.action
                if let img = NSImage(systemSymbolName: item.icon, accessibilityDescription: nil) {
                    mi.image = img
                }
                if item.isDestructive {
                    mi.attributedTitle = NSAttributedString(string: item.title, attributes: [.foregroundColor: NSColor.systemRed])
                }
                mi.isEnabled = !item.isDisabled
                menu.addItem(mi)
            }
        }
        let point = NSPoint(x: 0, y: bounds.height + 4)
        menu.popUp(positioning: nil, at: point, in: self)
    }

    @objc private func menuAction(_ sender: NSMenuItem) {
        if let action = sender.representedObject as? () -> Void {
            action()
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        if let backgroundColor {
            let bgColor = isHovered ? MenuRowStyle.nsHoverBackground : backgroundColor
            let path = NSBezierPath(roundedRect: bounds, xRadius: MenuRowStyle.cornerRadius, yRadius: MenuRowStyle.cornerRadius)
            bgColor.setFill()
            path.fill()
        }

        let textColor = NSColor(red: 32 / 255, green: 32 / 255, blue: 32 / 255, alpha: 1)
        let iconX = MenuRowStyle.horizontalPadding
        let textX = iconX + MenuRowStyle.iconSize + MenuRowStyle.iconTextGap
        let centerY = bounds.midY

        if let img = NSImage(named: iconAssetName) {
            let tinted = tintImage(img, color: textColor)
            let glyphSize = MenuIconSpec.glyphSize(for: iconAssetName)
            let imgRect = NSRect(
                x: iconX + (MenuRowStyle.iconSize - glyphSize.width) / 2,
                y: centerY - glyphSize.height / 2,
                width: glyphSize.width,
                height: glyphSize.height
            )
            tinted.draw(in: imgRect)
        }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: MenuRowStyle.textSize, weight: .medium),
            .foregroundColor: textColor,
        ]
        let textSize = (titleText as NSString).size(withAttributes: attrs)
        let textPoint = NSPoint(x: textX, y: centerY - textSize.height / 2)
        (titleText as NSString).draw(at: textPoint, withAttributes: attrs)

        if let shortcut {
            let shortcutAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: MenuRowStyle.textSize, weight: .medium),
                .foregroundColor: textColor.withAlphaComponent(0.40),
            ]
            let shortcutSize = (shortcut as NSString).size(withAttributes: shortcutAttrs)
            let shortcutPoint = NSPoint(x: bounds.maxX - MenuRowStyle.horizontalPadding - shortcutSize.width, y: centerY - shortcutSize.height / 2)
            (shortcut as NSString).draw(at: shortcutPoint, withAttributes: shortcutAttrs)
        } else if let trailingChevronAssetName, let img = NSImage(named: trailingChevronAssetName) {
            let chevronColor = textColor.withAlphaComponent(0.40)
            let tinted = tintImage(img, color: chevronColor)
            let chevronSize = MenuIconSpec.glyphSize(for: trailingChevronAssetName)
            let chevronRect = NSRect(
                x: bounds.maxX - MenuRowStyle.horizontalPadding - chevronSize.width,
                y: centerY - chevronSize.height / 2,
                width: chevronSize.width,
                height: chevronSize.height
            )
            tinted.draw(in: chevronRect)
        }
    }

    private func tintImage(_ image: NSImage, color: NSColor) -> NSImage {
        let tinted = image.copy() as! NSImage
        tinted.isTemplate = false
        tinted.lockFocus()
        color.set()
        let rect = NSRect(origin: .zero, size: tinted.size)
        rect.fill(using: .sourceAtop)
        tinted.unlockFocus()
        return tinted
    }
}

private struct MenuDivider: View {
    var body: some View {
        Rectangle()
            .fill(MenuRowStyle.background)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
            .frame(height: MenuRowStyle.dividerHeight)
    }
}
