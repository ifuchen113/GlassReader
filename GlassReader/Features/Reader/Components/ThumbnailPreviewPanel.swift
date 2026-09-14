import AppKit
import ImageIO
import PDFKit
import SwiftUI

struct ThumbnailPreviewPanel: View {
    @EnvironmentObject private var library: ReaderLibrary

    var body: some View {
        ScrollViewReader { reader in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(pageEntries, id: \.page.id) { entry in
                        Button {
                            library.jump(to: entry.index)
                        } label: {
                            HStack(spacing: 10) {
                                PageImage(loader: entry.page.loader, maxPixelSize: 360)
                                    .scaledToFit()
                                    .frame(width: 86, height: 116)
                                    .background(.white, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(entry.index + 1)")
                                        .font(.headline.monospacedDigit())
                                    Text(entry.page.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                Spacer()
                            }
                            .padding(8)
                            .background(
                                entry.index == library.currentIndex ? AnyShapeStyle(.tint.opacity(0.22)) : AnyShapeStyle(.clear),
                                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                            )
                        }
                        .buttonStyle(.plain)
                        .id(entry.index)
                    }
                }
                .padding(12)
            }
            .frame(width: 280, height: 480)
            .onAppear {
                reader.scrollTo(library.currentIndex, anchor: .center)
            }
        }
    }

    private var pageEntries: [(index: Int, page: ReaderPage)] {
        let entries = Array(library.pages.enumerated()).map { (index: $0.offset, page: $0.element) }
        return library.readingDirection == .rightToLeft ? Array(entries.reversed()) : entries
    }
}

extension Notification.Name {
    static let glassReaderZoomOut = Notification.Name("GlassReader.zoomOut")
    static let glassReaderZoomIn = Notification.Name("GlassReader.zoomIn")
    static let glassReaderZoomReset = Notification.Name("GlassReader.zoomReset")
}
