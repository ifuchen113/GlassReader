import AppKit
import ImageIO
import PDFKit
import SwiftUI

struct ArchivePasswordPrompt: Identifiable {
    let id = UUID()
    let url: URL
    let rootURL: URL
    let passwords: [String: String]
    let message: String
}

