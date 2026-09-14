import AppKit
import ImageIO
import PDFKit
import SwiftUI

enum ReadingDirection: String, CaseIterable, Identifiable, Codable {
    case leftToRight = "普通模式"
    case rightToLeft = "日漫模式"

    var id: String { rawValue }

    var layoutDirection: LayoutDirection {
        self == .rightToLeft ? .rightToLeft : .leftToRight
    }
}

