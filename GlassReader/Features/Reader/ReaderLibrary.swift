import AppKit
import ImageIO
import PDFKit
import SwiftUI

@MainActor
final class ReaderLibrary: ObservableObject {
    @Published var pages: [ReaderPage] = []
    @Published var currentIndex = 0
    @Published var sourceURL: URL?
    @Published var tabs: [ReaderTab] = []
    @Published var activeTabID: UUID?
    @Published var status = Localizer.text(.defaultStatus, .zh)
    @Published var favorites: [FavoriteItem] = []
    @Published var history: [FavoriteItem] = []
    @Published var isPrivateBrowsing = false
    @Published var isDoublePage = true
    @Published var readingDirection: ReadingDirection = .leftToRight
    @Published var language: AppLanguage = AppLanguage(rawValue: UserDefaults.standard.string(forKey: languageKey) ?? "") ?? .zh {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Self.languageKey)
            if pages.isEmpty, sourceURL == nil {
                status = t(.defaultStatus)
            }
        }
    }
    @Published var isSlideshowRunning = false
    @Published var slideshowInterval: Double = 4
    @Published var zoomMode: ZoomMode = ZoomMode.savedDefault {
        didSet { UserDefaults.standard.set(zoomMode.rawValue, forKey: Self.zoomModeKey) }
    }
    @Published var isFocusMode = false
    @Published var isImmersiveMode = false
    @Published var showsImmersiveSidebar = false
    @Published var showsPageBadges = true
    @Published var archivePasswordPrompt: ArchivePasswordPrompt?
    @Published var keepsTopOverlayOpen = false
    @Published var transitionSnapshot: NSImage?

    var extractedFolders: [URL] = []
    var slideshowTimer: Timer?
    var activeLoadID: UUID?
    static let zoomModeKey = "GlassReader.zoomMode"
    static let languageKey = "GlassReader.language"
    let favoritesKey = "GlassReader.favorite.paths"
    let historyKey = "GlassReader.history.paths"
    let tabsKey = "GlassReader.open.tabs"
    let activeTabKey = "GlassReader.open.activeTab"
    let supportedImages = Set(["jpg", "jpeg", "png", "webp", "gif", "bmp", "tiff", "tif", "heic"])
    let supportedArchives = Set(["zip", "cbz", "7z", "cb7", "rar", "cbr"])
    var didRestorePersistedTabs = false

    init() {
        loadFavorites()
        loadHistory()
        loadTabs()
        status = t(.defaultStatus)
    }

    func t(_ key: LKey) -> String {
        Localizer.text(key, language)
    }

    func format(_ key: LKey, _ args: CVarArg...) -> String {
        String(format: t(key), arguments: args)
    }

    func readingDirectionTitle(_ direction: ReadingDirection) -> String {
        direction == .leftToRight ? t(.directionNormal) : t(.directionManga)
    }

    func zoomModeTitle(_ mode: ZoomMode) -> String {
        switch mode {
        case .fitScreen: return t(.zoomFitScreen)
        case .fitWidth: return t(.zoomFitWidth)
        case .originalSize: return t(.zoomOriginal)
        case .fillScreen: return t(.zoomFillScreen)
        case .smartFit: return t(.zoomSmartFit)
        }
    }

    func sidebarModeTitle(_ mode: SidebarListMode) -> String {
        mode == .favorites ? t(.favorites) : t(.history)
    }

    var pageCount: Int { pages.count }

    var currentPair: [ReaderPage] {
        guard !pages.isEmpty else { return [] }
        if isDoublePage {
            let first = clamped(currentIndex)
            let second = clamped(first + 1)
            if second != first {
                return [pages[first], pages[second]]
            }
        }
        return [pages[clamped(currentIndex)]]
    }

    var visiblePages: [ReaderPage] {
        readingDirection == .rightToLeft ? currentPair.reversed() : currentPair
    }

}
