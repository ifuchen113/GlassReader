import AppKit
import ImageIO
import PDFKit
import SwiftUI

extension PageLoader {
    @MainActor
    var aspectRatio: CGFloat {
        switch self {
        case .image(let url):
            return ImageFileLoader.aspectRatio(for: url) ?? 0.707
        case .pdfPage(let url, let index):
            guard let document = PDFDocument(url: url),
                  let page = document.page(at: index) else { return 0.707 }
            let bounds = page.bounds(for: .mediaBox)
            guard bounds.height > 0 else { return 0.707 }
            return bounds.width / bounds.height
        }
    }

    @MainActor
    var pointSize: CGSize {
        switch self {
        case .image(let url):
            let pixelSize = ImageFileLoader.pixelSize(for: url) ?? CGSize(width: 1200, height: 1600)
            let scale = NSScreen.main?.backingScaleFactor ?? 2
            return CGSize(width: pixelSize.width / scale, height: pixelSize.height / scale)
        case .pdfPage(let url, let index):
            guard let document = PDFDocument(url: url),
                  let page = document.page(at: index) else {
                return CGSize(width: 800, height: 1100)
            }
            return page.bounds(for: .mediaBox).size
        }
    }
}
