import AppKit
import ImageIO
import PDFKit
import SwiftUI

@MainActor
extension ReaderLibrary {
    func cancelArchivePassword() {
        archivePasswordPrompt = nil
        status = t(.passwordCancelled)
    }

    func toggleFavoriteCurrentSource() {
        guard let sourceURL else { return }
        let path = sourceURL.path
        if favorites.contains(where: { $0.path == path }) {
            favorites.removeAll { $0.path == path }
            saveFavorites()
            status = "\(t(.favoriteRemoved)) \(sourceURL.lastPathComponent)"
            return
        }
        favorites.insert(
            FavoriteItem(id: UUID(), name: sourceURL.lastPathComponent, path: path, addedAt: Date()),
            at: 0
        )
        saveFavorites()
        status = "\(t(.favoriteAdded)) \(sourceURL.lastPathComponent)"
    }

    func favoriteCurrentSource() {
        guard !isCurrentSourceFavorite() else {
            status = t(.alreadyFavorite)
            return
        }
        toggleFavoriteCurrentSource()
    }

    func isCurrentSourceFavorite() -> Bool {
        guard let sourceURL else { return false }
        return favorites.contains { $0.path == sourceURL.path }
    }

    func removeFavorite(_ favorite: FavoriteItem) {
        favorites.removeAll { $0.id == favorite.id }
        saveFavorites()
    }

    func removeHistory(_ item: FavoriteItem) {
        history.removeAll { $0.id == item.id || $0.path == item.path }
        saveHistory()
    }

    func clearHistory() {
        history.removeAll()
        saveHistory()
        status = t(.historyCleared)
    }

    func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: favoritesKey),
              let decoded = try? JSONDecoder().decode([FavoriteItem].self, from: data) else { return }
        favorites = decoded
    }

    func saveFavorites() {
        guard let data = try? JSONEncoder().encode(favorites) else { return }
        UserDefaults.standard.set(data, forKey: favoritesKey)
    }

    func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode([FavoriteItem].self, from: data) else { return }
        history = decoded
    }

    func saveHistory() {
        guard let data = try? JSONEncoder().encode(history) else { return }
        UserDefaults.standard.set(data, forKey: historyKey)
    }

    func savedProgressIndex(for url: URL) -> Int {
        let path = url.path
        if let historyItem = history.first(where: { $0.path == path }) {
            return historyItem.lastPageIndex
        }
        if let favoriteItem = favorites.first(where: { $0.path == path }) {
            return favoriteItem.lastPageIndex
        }
        return 0
    }

    func restoreReadingLayout(for url: URL) {
        let path = url.path
        let item = history.first(where: { $0.path == path })
            ?? favorites.first(where: { $0.path == path })
        if let savedDoublePage = item?.isDoublePage {
            isDoublePage = savedDoublePage
        }
        if let rawValue = item?.readingDirectionRawValue,
           let savedDirection = ReadingDirection(rawValue: rawValue) {
            readingDirection = savedDirection
        }
    }

    func saveCurrentReadingProgress() {
        guard let sourceURL, !pages.isEmpty else { return }
        updateActiveTab(pages: pages, currentIndex: currentIndex, archivePasswords: activeArchivePasswords())
        recordHistory(sourceURL, currentIndex: currentIndex, pageCount: pages.count)
        let path = sourceURL.path
        if let favoriteIndex = favorites.firstIndex(where: { $0.path == path }) {
            favorites[favoriteIndex].lastPageIndex = currentIndex
            favorites[favoriteIndex].pageCount = pages.count
            favorites[favoriteIndex].isDoublePage = isDoublePage
            favorites[favoriteIndex].readingDirectionRawValue = readingDirection.rawValue
            favorites[favoriteIndex].addedAt = Date()
            saveFavorites()
        }
    }

    func activeArchivePasswords() -> [String: String] {
        guard let activeTabID,
              let tab = tabs.first(where: { $0.id == activeTabID }) else { return [:] }
        return tab.archivePasswords
    }

    func recordHistory(_ url: URL, currentIndex: Int, pageCount: Int) {
        guard !isPrivateBrowsing else { return }
        let path = url.path
        history.removeAll { $0.path == path }
        history.insert(
            FavoriteItem(
                id: UUID(),
                name: url.lastPathComponent,
                path: path,
                addedAt: Date(),
                lastPageIndex: currentIndex,
                pageCount: pageCount,
                isDoublePage: isDoublePage,
                readingDirectionRawValue: readingDirection.rawValue
            ),
            at: 0
        )
        if history.count > 100 {
            history.removeLast(history.count - 100)
        }
        saveHistory()
    }

}
