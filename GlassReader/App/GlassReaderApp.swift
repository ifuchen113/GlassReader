import AppKit
import ImageIO
import PDFKit
import SwiftUI

@main
struct GlassReaderApp: App {
    @StateObject private var library = ReaderLibrary()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(library)
                .frame(minWidth: 1080, minHeight: 720)
                .onOpenURL { url in
                    library.open(url)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(after: .newItem) {
                Button(library.t(.openLocalFile) + "...") { library.openWithPanel() }
                    .keyboardShortcut("o", modifiers: [.command])
                Button(library.t(.favoriteCurrent)) { library.toggleFavoriteCurrentSource() }
                    .keyboardShortcut("d", modifiers: [.command])
                Button(library.t(.shortcutClear)) { library.clearDocument() }
                    .keyboardShortcut("w", modifiers: [.command])
            }

            CommandMenu(library.t(.readerMenu)) {
                Button(library.t(.turnLeft)) { library.turnLeft() }
                    .keyboardShortcut(.leftArrow, modifiers: [])
                Button(library.t(.turnRight)) { library.turnRight() }
                    .keyboardShortcut(.rightArrow, modifiers: [])
                Button(library.t(.rematchSpreadAction)) { library.rematchSpreadForward() }
                    .keyboardShortcut("r", modifiers: [.command])
                Button(library.t(.shortcutSpreadBack)) { library.rematchSpreadBackward() }
                    .keyboardShortcut(.leftArrow, modifiers: [.command])
                Button(library.t(.shortcutSpreadForward)) { library.rematchSpreadForward() }
                    .keyboardShortcut(.rightArrow, modifiers: [.command])
                Button(library.t(.shortcutPageMode)) { library.toggleDoublePageMode() }
                    .keyboardShortcut("2", modifiers: [.command])
                Button(library.t(.shortcutDirection)) { library.toggleReadingDirection() }
                    .keyboardShortcut("l", modifiers: [.command])
                Button(library.t(.shortcutZoomOut)) {
                    NotificationCenter.default.post(name: .glassReaderZoomOut, object: nil)
                }
                    .keyboardShortcut("-", modifiers: [.command])
                Button(library.t(.shortcutZoomIn)) {
                    NotificationCenter.default.post(name: .glassReaderZoomIn, object: nil)
                }
                    .keyboardShortcut("+", modifiers: [.command])
                Button(library.t(.shortcutZoomReset)) {
                    NotificationCenter.default.post(name: .glassReaderZoomReset, object: nil)
                }
                    .keyboardShortcut("0", modifiers: [.command])
                Button(library.t(.pageDisplayToggle)) { library.showsPageBadges.toggle() }
                    .keyboardShortcut("p", modifiers: [.command])
                Button(library.t(.slideshowHelp)) { library.toggleSlideshow() }
                    .keyboardShortcut(.space, modifiers: [])
                Button(library.t(.fullscreen)) { library.toggleFullScreen() }
                    .keyboardShortcut("f", modifiers: [.command, .control])
                Button(library.t(.immersive)) { library.toggleImmersiveMode() }
                    .keyboardShortcut("f", modifiers: [.command, .shift])
                Button(library.t(.exitImmersive)) { library.exitImmersiveMode() }
                    .keyboardShortcut(.escape, modifiers: [])
            }
        }
    }
}

