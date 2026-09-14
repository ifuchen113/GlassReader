import AppKit
import ImageIO
import PDFKit
import SwiftUI

struct ReaderTab: Identifiable {
    let id: UUID
    let name: String
    let path: String
    var archivePasswords: [String: String] = [:]
    var pages: [ReaderPage] = []
    var currentIndex = 0
    var isDoublePage = true
    var readingDirection: ReadingDirection = .leftToRight

    init(id: UUID = UUID(), url: URL) {
        self.id = id
        self.name = url.lastPathComponent
        self.path = url.path
    }

    init(persisted: PersistedReaderTab) {
        self.id = persisted.id
        self.name = persisted.name
        self.path = persisted.path
        self.currentIndex = persisted.currentIndex
        self.isDoublePage = persisted.isDoublePage
        self.readingDirection = ReadingDirection(rawValue: persisted.readingDirectionRawValue) ?? .leftToRight
    }
}

struct PersistedReaderTab: Codable {
    let id: UUID
    let name: String
    let path: String
    let currentIndex: Int
    let isDoublePage: Bool
    let readingDirectionRawValue: String

    init(tab: ReaderTab) {
        id = tab.id
        name = tab.name
        path = tab.path
        currentIndex = tab.currentIndex
        isDoublePage = tab.isDoublePage
        readingDirectionRawValue = tab.readingDirection.rawValue
    }
}

