import AppKit
import ImageIO
import PDFKit
import SwiftUI

struct ToolbarView: View {
    @EnvironmentObject private var library: ReaderLibrary
    @State private var showsShortcuts = false
    @State private var showsThumbnails = false

    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 6) {
                Picker(library.t(.zoom), selection: $library.zoomMode) {
                    ForEach(ZoomMode.allCases) { mode in
                        Text(library.zoomModeTitle(mode)).tag(mode)
                    }
                }
                .labelsHidden()
                .frame(width: 112)
                .help(library.t(.zoomHelp))

                Button { library.rematchSpreadBackward() } label: {
                    Image(systemName: "arrowtriangle.left.fill")
                }
                .help(library.t(.spreadBackHelp))

                Button { library.rematchSpreadForward() } label: {
                    Image(systemName: "arrowtriangle.right.fill")
                }
                .help(library.t(.spreadForwardHelp))

                Divider()
                    .frame(height: 24)

                Button {
                    withAnimation(.snappy(duration: 0.18)) {
                        library.toggleDoublePageMode()
                    }
                } label: {
                    PageModeGlyph(pageCount: library.isDoublePage ? 2 : 1)
                }
                .help(library.isDoublePage ? library.t(.switchSingle) : library.t(.switchDouble))

                Button {
                    withAnimation(.snappy(duration: 0.18)) {
                        library.toggleReadingDirection()
                    }
                } label: {
                    DirectionModeGlyph(direction: library.readingDirection)
                }
                .help(library.readingDirection == .leftToRight ? library.t(.switchManga) : library.t(.switchNormal))

                Button { library.toggleSlideshow() } label: {
                    Image(systemName: library.isSlideshowRunning ? "pause.circle.fill" : "play.circle")
                }
                .help(library.t(.slideshowHelp))
            }
            .layoutPriority(3)

            VStack(alignment: .leading, spacing: 2) {
                Text(library.sourceURL?.lastPathComponent ?? library.t(.unopened))
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(library.status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            .layoutPriority(-1)

            HStack(spacing: 6) {
                if library.pageCount > 0 {
                    Text("\(library.currentIndex + 1) / \(library.pageCount)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .frame(minWidth: 58, alignment: .trailing)
                }

                Button {
                    showsThumbnails.toggle()
                } label: {
                    Image(systemName: "rectangle.grid.1x2")
                }
                .help(library.t(.thumbnails))
                .popover(isPresented: $showsThumbnails, arrowEdge: .bottom) {
                    ThumbnailPreviewPanel()
                        .environmentObject(library)
                }
                .onChange(of: showsThumbnails) { _, isPresented in
                    library.keepsTopOverlayOpen = isPresented || showsShortcuts || library.showsImmersiveSidebar
                }

                Button { library.toggleFullScreen() } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                }
                .help(library.t(.fullscreen))

                Button { library.toggleImmersiveMode() } label: {
                    Image(systemName: "viewfinder")
                }
                .help(library.isImmersiveMode ? library.t(.exitImmersive) : library.t(.immersive))

                Button {
                    showsShortcuts.toggle()
                } label: {
                    Image(systemName: "keyboard")
                }
            .help(library.t(.shortcuts))
            .popover(isPresented: $showsShortcuts, arrowEdge: .bottom) {
                ShortcutPanel()
                    .environmentObject(library)
            }
            .onChange(of: showsShortcuts) { _, isPresented in
                library.keepsTopOverlayOpen = isPresented || showsThumbnails || library.showsImmersiveSidebar
            }
            }
            .layoutPriority(4)
        }
        .buttonStyle(ToolbarPillButtonStyle())
        .frame(maxWidth: .infinity)
        .animation(.easeOut(duration: 0.18), value: library.isFocusMode)
    }
}

