import AppKit
import ImageIO

@MainActor
enum ScreenshotPasteboard {
    private static var registeredScales: [String: CGFloat] = [:]

    static func registerPasteScale(_ scale: CGFloat?, for url: URL?) {
        guard let url, let scale, scale > 0 else { return }
        registeredScales[url.standardizedFileURL.path] = scale
    }

    static func pasteScale(for url: URL?, imageSize: CGSize? = nil, preferredScreen: NSScreen? = nil) -> CGFloat {
        guard AppPreferences.copyScreenshotsAtRetinaScale else { return 1 }

        if let url, let registered = registeredScales[url.standardizedFileURL.path], registered > 0 {
            return registered
        }

        if let url {
            let rawURL = CaptureOrchestrator.resolveRawSource(for: url)
            if rawURL != url {
                if let registered = registeredScales[rawURL.standardizedFileURL.path], registered > 0 {
                    return registered
                }
                if let rawSize = imagePixelSize(at: rawURL) {
                    return inferredScale(forPixelSize: rawSize)
                }
            }
        }

        if let preferredScreen {
            return max(preferredScreen.backingScaleFactor, 1)
        }

        guard let imageSize = imageSize ?? imagePixelSize(at: url) else { return 1 }
        let inferredScale = inferredScale(forPixelSize: imageSize)
        if inferredScale > 1 {
            return inferredScale
        }

        return max(NSScreen.main?.backingScaleFactor ?? 1, 1)
    }

    @discardableResult
    static func copyImage(at url: URL, preferredScreen: NSScreen? = nil) -> Bool {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return false }
        copyImage(cgImage, sourceURL: url, preferredScreen: preferredScreen)
        return true
    }

    static func copyImage(_ cgImage: CGImage, sourceURL: URL? = nil, preferredScreen: NSScreen? = nil, explicitScale: CGFloat? = nil) {
        let pixelSize = CGSize(width: cgImage.width, height: cgImage.height)
        let scale = AppPreferences.copyScreenshotsAtRetinaScale
            ? (explicitScale ?? pasteScale(for: sourceURL, imageSize: pixelSize, preferredScreen: preferredScreen))
            : 1
        let displayScale = max(scale, 1)
        let logicalSize = NSSize(width: pixelSize.width / displayScale, height: pixelSize.height / displayScale)

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        if let pasteboardItem = pasteboardItem(for: cgImage, logicalSize: logicalSize) {
            pasteboard.writeObjects([pasteboardItem])
        } else {
            let nsImage = NSImage(cgImage: cgImage, size: logicalSize)
            pasteboard.writeObjects([nsImage])
        }
    }

    static func copyImage(_ image: NSImage, sourceURL: URL? = nil, preferredScreen: NSScreen? = nil) {
        if let sourceURL {
            if copyImage(at: sourceURL, preferredScreen: preferredScreen) {
                return
            }
        }

        var rect = CGRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else { return }
        copyImage(cgImage, preferredScreen: preferredScreen)
    }

    private static func imagePixelSize(at url: URL?) -> CGSize? {
        guard let url,
              let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? NSNumber,
              let height = properties[kCGImagePropertyPixelHeight] as? NSNumber else { return nil }
        return CGSize(width: CGFloat(width.doubleValue), height: CGFloat(height.doubleValue))
    }

    private static func inferredScale(forPixelSize pixelSize: CGSize) -> CGFloat {
        for screen in NSScreen.screens {
            let screenScale = max(screen.backingScaleFactor, 1)
            let screenPixelSize = CGSize(
                width: screen.frame.width * screenScale,
                height: screen.frame.height * screenScale
            )

            if approximatelyEqual(pixelSize.width, screenPixelSize.width),
               approximatelyEqual(pixelSize.height, screenPixelSize.height) {
                return screenScale
            }
        }

        return 1
    }

    private static func approximatelyEqual(_ lhs: CGFloat, _ rhs: CGFloat) -> Bool {
        abs(lhs - rhs) <= 2
    }

    private static func pasteboardItem(for cgImage: CGImage, logicalSize: NSSize) -> NSPasteboardItem? {
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        bitmap.size = logicalSize

        let item = NSPasteboardItem()
        var hasData = false

        if let pngData = bitmap.representation(using: .png, properties: [:]) {
            item.setData(pngData, forType: .png)
            hasData = true
        }

        if let tiffData = bitmap.representation(using: .tiff, properties: [:]) {
            item.setData(tiffData, forType: .tiff)
            hasData = true
        }

        return hasData ? item : nil
    }
}
