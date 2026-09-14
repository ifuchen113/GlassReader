import AppKit
import ImageIO
import PDFKit
import SwiftUI

@MainActor
extension ReaderLibrary {
    func handleKeyEvent(_ event: NSEvent) -> Bool {
        if keyName(for: event) == "Esc", isImmersiveMode {
            exitImmersiveMode()
            return true
        }
        return false
    }

    func openWithPanel() {
        let panel = NSOpenPanel()
        panel.title = t(.chooseReaderFile)
        panel.prompt = t(.open)
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true

        if panel.runModal() == .OK {
            panel.urls.forEach { open($0) }
        }
    }

    func openDroppedItemProviders(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers where provider.hasItemConformingToTypeIdentifier("public.file-url") {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                let url = Self.fileURL(fromDroppedItem: item)
                guard let url else { return }
                DispatchQueue.main.async {
                    self.open(url)
                }
            }
            return true
        }
        return false
    }

    func openFavorite(_ favorite: FavoriteItem) {
        open(URL(fileURLWithPath: favorite.path), restoreIndex: favorite.lastPageIndex)
    }

    func openHistory(_ item: FavoriteItem) {
        open(URL(fileURLWithPath: item.path), restoreIndex: item.lastPageIndex)
    }

    func restorePersistedTabsIfNeeded() {
        guard !didRestorePersistedTabs else { return }
        didRestorePersistedTabs = true
        guard sourceURL == nil,
              let tab = tabs.first(where: { $0.id == activeTabID }) ?? tabs.first else { return }

        activeTabID = tab.id
        isDoublePage = tab.isDoublePage
        readingDirection = tab.readingDirection
        open(
            URL(fileURLWithPath: tab.path),
            restoreIndex: tab.currentIndex,
            makeTab: false,
            restoreLayoutFromHistory: false
        )
    }

    func togglePrivateBrowsing() {
        isPrivateBrowsing.toggle()
        status = isPrivateBrowsing ? t(.privateOn) : t(.privateOff)
    }

    func clearDocument() {
        if let activeTabID {
            closeTab(activeTabID)
        } else {
            resetDocumentState()
        }
    }

    func open(
        _ url: URL,
        password: String? = nil,
        restoreIndex: Int? = nil,
        archivePasswords: [String: String] = [:],
        makeTab: Bool = true,
        restoreLayoutFromHistory: Bool = true
    ) {
        if makeTab {
            saveCurrentReadingProgress()
        }
        stopSlideshow()
        if makeTab {
            if let existing = tabs.first(where: { $0.path == url.path }) {
                if password == nil, restoreIndex == nil, !existing.pages.isEmpty {
                    activateTab(existing)
                    return
                }
                activeTabID = existing.id
            } else {
                let tab = ReaderTab(url: url)
                tabs.append(tab)
                activeTabID = tab.id
            }
            saveTabs()
        }
        guard let loadTabID = activeTabID else { return }
        archivePasswordPrompt = nil
        status = password == nil ? "\(t(.open)) \(url.lastPathComponent)..." : "\(t(.passwordTitle)) \(url.lastPathComponent)..."
        var passwords = archivePasswords
        if let activeTab = tabs.first(where: { $0.id == activeTabID }) {
            for (key, value) in activeTab.archivePasswords where passwords[key] == nil {
                passwords[key] = value
            }
        }
        if let password {
            rememberArchivePassword(password, for: url, in: &passwords)
        }
        let loadID = UUID()
        activeLoadID = loadID

        Task {
            do {
                let loaded = try await loadPages(from: url, passwords: passwords)
                await MainActor.run {
                    guard self.activeLoadID == loadID, self.activeTabID == loadTabID else { return }
                    let savedIndex = restoreIndex ?? self.savedProgressIndex(for: url)
                    if restoreLayoutFromHistory {
                        self.restoreReadingLayout(for: url)
                    }
                    self.sourceURL = url
                    self.pages = loaded
                    self.currentIndex = loaded.isEmpty ? 0 : self.clamped(savedIndex)
                    self.archivePasswordPrompt = nil
                    self.status = loaded.isEmpty ? self.t(.noReadablePages) : "\(url.lastPathComponent) · \(loaded.count) 页"
                    self.updateTab(
                        loadTabID,
                        pages: loaded,
                        currentIndex: self.currentIndex,
                        archivePasswords: passwords
                    )
                    self.recordHistory(url, currentIndex: self.currentIndex, pageCount: loaded.count)
                }
            } catch ReaderError.archiveNeedsPassword(let targetURL) {
                await MainActor.run {
                    guard self.activeLoadID == loadID, self.activeTabID == loadTabID else { return }
                    self.pages = []
                    self.status = self.t(.archiveNeedsPasswordStatus)
                    self.archivePasswordPrompt = ArchivePasswordPrompt(
                        url: targetURL,
                        rootURL: url,
                        passwords: passwords,
                        message: targetURL == url
                            ? self.t(.firstPasswordMessage)
                            : self.t(.nestedPasswordMessage)
                    )
                }
            } catch {
                await MainActor.run {
                    guard self.activeLoadID == loadID, self.activeTabID == loadTabID else { return }
                    self.pages = []
                    if self.isSupportedArchive(url) {
                        let message = password == nil
                            ? self.t(.firstPasswordMessage)
                            : self.t(.archivePasswordFailed)
                        self.status = password == nil ? self.t(.archiveMightNeedPassword) : self.t(.archivePasswordFailed)
                        self.archivePasswordPrompt = ArchivePasswordPrompt(
                            url: url,
                            rootURL: url,
                            passwords: passwords,
                            message: message
                        )
                    } else {
                        self.status = "\(self.t(.cannotOpen)): \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    func submitArchivePassword(_ prompt: ArchivePasswordPrompt, password: String) {
        archivePasswordPrompt = nil
        var passwords = prompt.passwords
        rememberArchivePassword(password, for: prompt.url, in: &passwords)
        open(
            prompt.rootURL,
            restoreIndex: savedProgressIndex(for: prompt.rootURL),
            archivePasswords: passwords,
            makeTab: false,
            restoreLayoutFromHistory: false
        )
    }

}
