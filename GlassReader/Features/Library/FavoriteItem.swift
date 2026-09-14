import AppKit
import ImageIO
import PDFKit
import SwiftUI

struct FavoriteItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var path: String
    var addedAt: Date
    var lastPageIndex: Int = 0
    var pageCount: Int = 0
    var isDoublePage: Bool?
    var readingDirectionRawValue: String?

    init(
        id: UUID,
        name: String,
        path: String,
        addedAt: Date,
        lastPageIndex: Int = 0,
        pageCount: Int = 0,
        isDoublePage: Bool? = nil,
        readingDirectionRawValue: String? = nil
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.addedAt = addedAt
        self.lastPageIndex = lastPageIndex
        self.pageCount = pageCount
        self.isDoublePage = isDoublePage
        self.readingDirectionRawValue = readingDirectionRawValue
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case path
        case addedAt
        case lastPageIndex
        case pageCount
        case isDoublePage
        case readingDirectionRawValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        path = try container.decode(String.self, forKey: .path)
        addedAt = try container.decode(Date.self, forKey: .addedAt)
        lastPageIndex = try container.decodeIfPresent(Int.self, forKey: .lastPageIndex) ?? 0
        pageCount = try container.decodeIfPresent(Int.self, forKey: .pageCount) ?? 0
        isDoublePage = try container.decodeIfPresent(Bool.self, forKey: .isDoublePage)
        readingDirectionRawValue = try container.decodeIfPresent(String.self, forKey: .readingDirectionRawValue)
    }
}

