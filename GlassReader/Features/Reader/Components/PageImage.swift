import AppKit
import ImageIO
import PDFKit
import SwiftUI

struct PageImage: View {
    @EnvironmentObject private var library: ReaderLibrary
    let loader: PageLoader
    var maxPixelSize: CGFloat = 4096

    var body: some View {
        Group {
            if let image = loadImage() {
                Image(nsImage: image)
                    .resizable()
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                    Text(library.t(.unablePage))
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    private func loadImage() -> NSImage? {
        switch loader {
        case .image(let url):
            return ImageFileLoader.image(for: url, maxPixelSize: maxPixelSize)
        case .pdfPage(let url, let index):
            return ImageFileLoader.pdfImage(for: url, pageIndex: index, maxPixelSize: maxPixelSize)
        }
    }
}

