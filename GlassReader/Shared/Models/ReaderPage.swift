import AppKit
import ImageIO
import PDFKit
import SwiftUI

struct ReaderPage: Identifiable, Hashable {
    let id = UUID()
    let displayName: String
    let sourceURL: URL
    let sortKey: String
    let loader: PageLoader
}

enum PageLoader: Hashable {
    case image(URL)
    case pdfPage(URL, Int)
}

