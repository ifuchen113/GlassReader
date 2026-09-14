import AppKit
import ImageIO
import PDFKit
import SwiftUI

@MainActor
extension ReaderLibrary {
    func activateTab(_ tab: ReaderTab) {
        guard activeTabID != tab.id || sourceURL?.path != tab.path else { return }
        saveCurrentReadingProgress()
        activeLoadID = nil
        activeTabID = tab.id
        isDoublePage = tab.isDoublePage
        readingDirection = tab.readingDirection
        saveTabs()

        if !tab.pages.isEmpty {
            stopSlideshow()
            sourceURL = URL(fileURLWithPath: tab.path)
            pages = tab.pages
            currentIndex = clamped(tab.currentIndex)
            archivePasswordPrompt = nil
            status = "\(sourceURL?.lastPathComponent ?? tab.name) · \(pages.count) 页"
            return
        }

        open(
            URL(fileURLWithPath: tab.path),
            restoreIndex: savedProgressIndex(for: URL(fileURLWithPath: tab.path)),
            makeTab: false,
            restoreLayoutFromHistory: false
        )
    }

    func closeTab(_ tabID: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == tabID }) else { return }
        let wasActive = activeTabID == tabID
        if wasActive {
            saveCurrentReadingProgress()
            stopSlideshow()
        }
        tabs.remove(at: index)
        saveTabs()

        guard wasActive else { return }
        if tabs.isEmpty {
            activeTabID = nil
            saveTabs()
            resetDocumentState()
            return
        }

        let nextIndex = min(index, tabs.count - 1)
        let nextTab = tabs[nextIndex]
        activateTab(nextTab)
    }

    func resetDocumentState() {
        stopSlideshow()
        activeLoadID = nil
        pages = []
        currentIndex = 0
        sourceURL = nil
        status = t(.defaultStatus)
        archivePasswordPrompt = nil
    }

    func updateActiveTab(pages: [ReaderPage], currentIndex: Int, archivePasswords: [String: String]) {
        guard let activeTabID,
              tabs.contains(where: { $0.id == activeTabID }) else { return }
        updateTab(
            activeTabID,
            pages: pages,
            currentIndex: currentIndex,
            archivePasswords: archivePasswords
        )
    }

    func updateTab(_ tabID: UUID, pages: [ReaderPage], currentIndex: Int, archivePasswords: [String: String]) {
        guard let tabIndex = tabs.firstIndex(where: { $0.id == tabID }) else { return }
        tabs[tabIndex].pages = pages
        tabs[tabIndex].currentIndex = currentIndex
        tabs[tabIndex].isDoublePage = isDoublePage
        tabs[tabIndex].readingDirection = readingDirection
        tabs[tabIndex].archivePasswords = archivePasswords
        saveTabs()
    }

    func loadTabs() {
        guard let data = UserDefaults.standard.data(forKey: tabsKey),
              let persistedTabs = try? JSONDecoder().decode([PersistedReaderTab].self, from: data) else {
            return
        }

        tabs = persistedTabs
            .filter { FileManager.default.fileExists(atPath: $0.path) }
            .map(ReaderTab.init(persisted:))

        if let rawID = UserDefaults.standard.string(forKey: activeTabKey),
           let id = UUID(uuidString: rawID),
           tabs.contains(where: { $0.id == id }) {
            activeTabID = id
        } else {
            activeTabID = tabs.first?.id
        }
    }

    func saveTabs() {
        let persistedTabs = tabs.map(PersistedReaderTab.init(tab:))
        if let data = try? JSONEncoder().encode(persistedTabs) {
            UserDefaults.standard.set(data, forKey: tabsKey)
        }
        if let activeTabID {
            UserDefaults.standard.set(activeTabID.uuidString, forKey: activeTabKey)
        } else {
            UserDefaults.standard.removeObject(forKey: activeTabKey)
        }
    }

}
