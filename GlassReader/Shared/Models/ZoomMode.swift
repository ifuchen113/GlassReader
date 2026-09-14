import AppKit
import ImageIO
import PDFKit
import SwiftUI

enum ZoomMode: String, CaseIterable, Identifiable {
    case fitScreen = "适应屏幕"
    case fitWidth = "适应宽度"
    case originalSize = "原始大小"
    case fillScreen = "填满屏幕"
    case smartFit = "智能适应"

    var id: String { rawValue }

    private static let storageKey = "GlassReader.zoomMode"

    static var savedDefault: ZoomMode {
        let saved = UserDefaults.standard.string(forKey: storageKey)
        if saved == "适应" { return .fitScreen }
        if saved == "宽度" { return .fitWidth }
        if saved == ZoomMode.smartFit.rawValue { return .fitScreen }
        return saved.flatMap(ZoomMode.init(rawValue:)) ?? .fitScreen
    }

    func resolved(forAspectRatio aspectRatio: CGFloat) -> ZoomMode {
        guard self == .smartFit else { return self }
        if aspectRatio < 0.85 {
            return .fitWidth
        }
        return .fitScreen
    }
}

