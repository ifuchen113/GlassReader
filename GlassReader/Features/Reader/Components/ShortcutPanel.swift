import AppKit
import ImageIO
import PDFKit
import SwiftUI

struct ShortcutPanel: View {
    @EnvironmentObject private var library: ReaderLibrary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(library.t(.shortcuts))
                .font(.headline)
            ShortcutRow(systemImage: "folder", title: library.t(.openLocalFile), keys: "⌘O") {
                library.openWithPanel()
            }
            ShortcutRow(systemImage: "xmark.circle", title: library.t(.shortcutClear), keys: "⌘W") {
                library.clearDocument()
            }
            ShortcutRow(systemImage: library.isCurrentSourceFavorite() ? "star.fill" : "star", title: library.isCurrentSourceFavorite() ? library.t(.unfavoriteCurrent) : library.t(.favoriteCurrent), keys: "⌘D") {
                library.toggleFavoriteCurrentSource()
            }
            ShortcutRow(systemImage: library.isPrivateBrowsing ? "eye.slash.fill" : "eye", title: library.t(.shortcutPrivate), keys: "点击") {
                library.togglePrivateBrowsing()
            }
            ShortcutRow(systemImage: "arrowtriangle.left.fill", title: library.t(.shortcutSpreadBack), keys: "⌘←") {
                library.rematchSpreadBackward()
            }
            ShortcutRow(systemImage: "arrowtriangle.right.fill", title: library.t(.shortcutSpreadForward), keys: "⌘→") {
                library.rematchSpreadForward()
            }
            ShortcutRow(title: library.t(.shortcutPageMode), keys: "⌘2") {
                PageModeGlyph(pageCount: library.isDoublePage ? 2 : 1)
            } action: {
                withAnimation(.snappy(duration: 0.18)) {
                    library.toggleDoublePageMode()
                }
            }
            ShortcutRow(title: library.t(.shortcutDirection), keys: "⌘L") {
                DirectionModeGlyph(direction: library.readingDirection)
            } action: {
                withAnimation(.snappy(duration: 0.18)) {
                    library.toggleReadingDirection()
                }
            }
            ShortcutRow(systemImage: "minus.magnifyingglass", title: library.t(.shortcutZoomOut), keys: "⌘−") {
                NotificationCenter.default.post(name: .glassReaderZoomOut, object: nil)
            }
            ShortcutRow(systemImage: "plus.magnifyingglass", title: library.t(.shortcutZoomIn), keys: "⌘+") {
                NotificationCenter.default.post(name: .glassReaderZoomIn, object: nil)
            }
            ShortcutRow(systemImage: "1.magnifyingglass", title: library.t(.shortcutZoomReset), keys: "⌘0") {
                NotificationCenter.default.post(name: .glassReaderZoomReset, object: nil)
            }
            ShortcutRow(systemImage: library.showsPageBadges ? "number.circle.fill" : "number.circle", title: library.t(.pageDisplayToggle), keys: "⌘P") {
                library.showsPageBadges.toggle()
            }
            ShortcutRow(systemImage: library.isSlideshowRunning ? "pause.circle.fill" : "play.circle", title: library.t(.slideshowHelp), keys: "Space") {
                library.toggleSlideshow()
            }
            ShortcutRow(systemImage: "arrow.up.left.and.arrow.down.right", title: library.t(.fullscreen), keys: "⌃⌘F") {
                library.toggleFullScreen()
            }
            ShortcutRow(systemImage: "viewfinder", title: library.t(.immersive), keys: "⇧⌘F") {
                library.toggleImmersiveMode()
            }
            ShortcutRow(systemImage: "escape", title: library.t(.exitImmersive), keys: "Esc") {
                library.exitImmersiveMode()
            }
            Divider()
                .padding(.vertical, 2)
            Text(library.t(.author))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(width: 340)
    }
}

struct ShortcutRow<Icon: View>: View {
    let title: String
    let keys: String
    @ViewBuilder var icon: Icon
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                icon
                    .frame(width: 24)
                    .foregroundStyle(.secondary)
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                Text(keys)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

extension ShortcutRow where Icon == Image {
    init(systemImage: String, title: String, keys: String, action: @escaping () -> Void) {
        self.title = title
        self.keys = keys
        self.icon = Image(systemName: systemImage)
        self.action = action
    }
}

