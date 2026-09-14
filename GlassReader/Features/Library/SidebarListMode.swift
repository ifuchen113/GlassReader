import AppKit
import ImageIO
import PDFKit
import SwiftUI

enum SidebarListMode: String, CaseIterable, Identifiable {
    case favorites = "收藏"
    case history = "历史"

    var id: String { rawValue }
}

