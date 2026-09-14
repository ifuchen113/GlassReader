import AppKit
import ImageIO
import PDFKit
import SwiftUI

enum ReaderError: LocalizedError {
    case unsupportedFile
    case unreadablePDF
    case archiveExtractionFailed
    case missingArchiveTool(String)
    case archiveNeedsPassword(URL)

    var errorDescription: String? {
        let language = AppLanguage(rawValue: UserDefaults.standard.string(forKey: "GlassReader.language") ?? "") ?? .zh
        switch self {
        case .unsupportedFile:
            return Localizer.text(.unsupportedFile, language)
        case .unreadablePDF:
            return Localizer.text(.unreadablePDF, language)
        case .archiveExtractionFailed:
            return Localizer.text(.archiveExtractionFailed, language)
        case .missingArchiveTool(let format):
            return String(format: Localizer.text(.missingArchiveTool, language), format)
        case .archiveNeedsPassword(let url):
            return String(format: Localizer.text(.archiveNeedsPasswordError, language), url.lastPathComponent)
        }
    }
}

