import AppKit
import ImageIO
import PDFKit
import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var library: ReaderLibrary
    @State private var listMode: SidebarListMode = .favorites

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                Spacer(minLength: 48)
                VStack(alignment: .trailing, spacing: 5) {
                    Text("GlassReader")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                    Text(library.t(.tagline))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Button {
                library.openWithPanel()
            } label: {
                Label(library.t(.openLocalFile), systemImage: "folder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            VStack(alignment: .leading, spacing: 10) {
                Text(library.t(.view))
                    .font(.headline)

                ViewSettingRow(title: library.t(.doublePage)) {
                    Toggle(
                        "",
                        isOn: Binding(
                            get: { library.isDoublePage },
                            set: { newValue in
                                if library.isDoublePage != newValue {
                                    library.toggleDoublePageMode()
                                }
                            }
                        )
                    )
                    .labelsHidden()
                    .frame(width: sidebarSettingControlWidth, alignment: .trailing)
                }

                ViewSettingRow(title: library.t(.direction)) {
                    SidebarFixedDropdown(
                        title: library.readingDirectionTitle(library.readingDirection),
                        options: ReadingDirection.allCases,
                        optionTitle: { library.readingDirectionTitle($0) },
                        select: { library.setReadingDirection($0) }
                    )
                }

                ViewSettingRow(title: library.t(.zoom)) {
                    SidebarFixedDropdown(
                        title: library.zoomModeTitle(library.zoomMode),
                        options: ZoomMode.allCases,
                        optionTitle: { library.zoomModeTitle($0) },
                        select: { library.zoomMode = $0 }
                    )
                }

                ViewSettingRow(title: "Language") {
                    SidebarFixedDropdown(
                        title: library.language.nativeName,
                        options: AppLanguage.allCases,
                        optionTitle: { $0.nativeName },
                        select: { library.language = $0 }
                    )
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(library.t(.slideshow))
                        .font(.headline)
                    Spacer()
                    Button {
                        library.toggleSlideshow()
                    } label: {
                        Image(systemName: library.isSlideshowRunning ? "pause.fill" : "play.fill")
                    }
                    .buttonStyle(.borderless)
                }
                HStack {
                    FlatProgressSlider(
                        value: library.slideshowInterval,
                        range: 1...20,
                        step: 1,
                        onChange: { library.updateSlideshowInterval($0) }
                    )
                    .frame(height: 24)
                    Text("\(Int(library.slideshowInterval))s")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .frame(width: 34, alignment: .trailing)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Picker("列表", selection: $listMode) {
                        ForEach(SidebarListMode.allCases) { mode in
                            Text(library.sidebarModeTitle(mode)).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    Spacer()
                    if listMode == .favorites {
                        Button {
                            library.toggleFavoriteCurrentSource()
                        } label: {
                            Image(systemName: library.isCurrentSourceFavorite() ? "star.fill" : "star")
                        }
                        .buttonStyle(.borderless)
                        .disabled(library.sourceURL == nil)
                        .help(library.isCurrentSourceFavorite() ? library.t(.unfavoriteCurrent) : library.t(.favoriteCurrent))
                    } else {
                        HStack(spacing: 4) {
                            Button {
                                library.togglePrivateBrowsing()
                            } label: {
                                Image(systemName: library.isPrivateBrowsing ? "eye.slash.fill" : "eye")
                            }
                            .buttonStyle(.borderless)
                            .help(library.isPrivateBrowsing ? library.t(.privateOffHelp) : library.t(.privateOnHelp))

                            Button {
                                library.clearHistory()
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .disabled(library.history.isEmpty)
                            .help(library.t(.clearHistory))
                        }
                    }
                }

                if currentItems.isEmpty {
                    Text(emptyText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(currentItems) { item in
                                FavoriteRow(
                                    item: item,
                                    openAction: { open(item) },
                                    removeAction: { remove(item) }
                                )
                            }
                        }
                    }
                }
            }
            .padding(14)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(20)
        .background(.thinMaterial)
    }

    private var currentItems: [FavoriteItem] {
        listMode == .favorites ? library.favorites : library.history
    }

    private var emptyText: String {
        switch listMode {
        case .favorites:
            return library.t(.favoriteEmpty)
        case .history:
            return library.isPrivateBrowsing ? library.t(.privateBrowsingEmpty) : library.t(.historyEmpty)
        }
    }

    private func open(_ item: FavoriteItem) {
        listMode == .favorites ? library.openFavorite(item) : library.openHistory(item)
    }

    private func remove(_ item: FavoriteItem) {
        listMode == .favorites ? library.removeFavorite(item) : library.removeHistory(item)
    }
}

