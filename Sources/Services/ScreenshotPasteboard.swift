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
        return copyImage(cgImage, sourceURL: url, preferredScreen: preferredScreen)
    }

    @discardableResult
    static func copyImage(_ cgImage: CGImage, sourceURL: URL? = nil, preferredScreen: NSScreen? = nil, explicitScale: CGFloat? = nil) -> Bool {
        let pixelSize = CGSize(width: cgImage.width, height: cgImage.height)
        let scale = AppPreferences.copyScreenshotsAtRetinaScale
            ? (explicitScale ?? pasteScale(for: sourceURL, imageSize: pixelSize, preferredScreen: preferredScreen))
            : 1
        let displayScale = max(scale, 1)
        let logicalSize = NSSize(width: pixelSize.width / displayScale, height: pixelSize.height / displayScale)

        guard let payload = pasteboardPayload(for: cgImage, logicalSize: logicalSize) else {
            return false
        }

        return writePreparedPayload(payload)
    }

    @discardableResult
    static func copyImage(_ image: NSImage, sourceURL: URL? = nil, preferredScreen: NSScreen? = nil) -> Bool {
        if let sourceURL {
            if copyImage(at: sourceURL, preferredScreen: preferredScreen) {
                return true
            }
        }

        var rect = CGRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else { return false }
        return copyImage(cgImage, preferredScreen: preferredScreen)
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

    private static func pasteboardPayload(for cgImage: CGImage, logicalSize: NSSize) -> PasteboardPayload? {
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        bitmap.size = logicalSize

        let payload = PasteboardPayload(
            pngData: bitmap.representation(using: .png, properties: [:]),
            tiffData: bitmap.representation(using: .tiff, properties: [:])
        )

        return payload.hasData ? payload : nil
    }

    private static func writePreparedPayload(_ payload: PasteboardPayload) -> Bool {
        var types: [NSPasteboard.PasteboardType] = []
        if payload.pngData != nil { types.append(.png) }
        if payload.tiffData != nil { types.append(.tiff) }
        guard !types.isEmpty else { return false }

        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes(types, owner: nil)

        var wroteData = false
        if let pngData = payload.pngData {
            wroteData = pasteboard.setData(pngData, forType: .png) || wroteData
        }
        if let tiffData = payload.tiffData {
            wroteData = pasteboard.setData(tiffData, forType: .tiff) || wroteData
        }

        return wroteData
    }

    private struct PasteboardPayload {
        let pngData: Data?
        let tiffData: Data?

        var hasData: Bool {
            pngData != nil || tiffData != nil
        }
    }
}
