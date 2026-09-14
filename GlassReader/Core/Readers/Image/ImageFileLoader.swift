import AppKit
import ImageIO
import PDFKit
import SwiftUI

@MainActor
enum ImageFileLoader {
    private static let cache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 120
        cache.totalCostLimit = 320 * 1024 * 1024
        return cache
    }()

    static func aspectRatio(for url: URL) -> CGFloat? {
        guard let size = pixelSize(for: url), size.height > 0 else { return nil }
        return size.width / size.height
    }

    static func pixelSize(for url: URL) -> CGSize? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return nil
        }

        let width = numericCGFloat(properties[kCGImagePropertyPixelWidth])
        let height = numericCGFloat(properties[kCGImagePropertyPixelHeight])
        guard let width, let height, height > 0 else { return nil }
        return CGSize(width: width, height: height)
    }

    private static func numericCGFloat(_ value: Any?) -> CGFloat? {
        if let value = value as? CGFloat {
            return value
        }
        if let value = value as? NSNumber {
            return CGFloat(truncating: value)
        }
        if let value = value as? Double {
            return CGFloat(value)
        }
        if let value = value as? Int {
            return CGFloat(value)
        }
        return nil
    }

    static func image(for url: URL, maxPixelSize: CGFloat = 4096) -> NSImage? {
        let key = "\(url.path)#image#\(Int(maxPixelSize))" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        let image = NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
        cache.setObject(image, forKey: key, cost: cgImage.width * cgImage.height * 4)
        return image
    }

    static func pdfImage(for url: URL, pageIndex: Int, maxPixelSize: CGFloat) -> NSImage? {
        let key = "\(url.path)#pdf#\(pageIndex)#\(Int(maxPixelSize))" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        guard let document = PDFDocument(url: url),
              let page = document.page(at: pageIndex) else { return nil }
        let bounds = page.bounds(for: .mediaBox)
        guard bounds.width > 0, bounds.height > 0 else { return nil }
        let scale = min(maxPixelSize / max(bounds.width, bounds.height), 2)
        let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return nil
        }
        context.saveGState()
        context.scaleBy(x: scale, y: scale)
        page.draw(with: .mediaBox, to: context)
        context.restoreGState()
        image.unlockFocus()
        cache.setObject(image, forKey: key, cost: Int(size.width * size.height * 4))
        return image
    }
}
