import AppKit
import ImageIO
import PDFKit
import SwiftUI

struct PageSurface: View {
    @EnvironmentObject private var library: ReaderLibrary
    let page: ReaderPage
    let zoomScale: CGFloat
    let zoomAnchor: UnitPoint
    @Binding var panOffset: CGSize
    @State private var dragStartOffset: CGSize = .zero
    @State private var isDragging = false

    var body: some View {
        GeometryReader { proxy in
            let size = CGSize(width: max(proxy.size.width, 1), height: max(proxy.size.height, 1))
            let mode = library.zoomMode.resolved(forAspectRatio: page.loader.aspectRatio)
            content(mode: mode, size: proxy.size)
                .scaleEffect(zoomScale, anchor: .topLeading)
                .offset(
                    x: baseOffset(in: size).width + panOffset.width,
                    y: baseOffset(in: size).height + panOffset.height
                )
                .frame(width: size.width, height: size.height, alignment: .topLeading)
                .clipped()
                .contentShape(Rectangle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 3)
                        .onChanged { value in
                            guard zoomScale > 1 else { return }
                            if !isDragging {
                                dragStartOffset = panOffset
                                isDragging = true
                            }
                            let base = baseOffset(in: size)
                            let total = CGSize(
                                width: base.width + dragStartOffset.width + value.translation.width,
                                height: base.height + dragStartOffset.height + value.translation.height
                            )
                            let clamped = clampedTotalOffset(total, scale: zoomScale, size: size)
                            panOffset = CGSize(
                                width: clamped.width - base.width,
                                height: clamped.height - base.height
                            )
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func baseOffset(in size: CGSize) -> CGSize {
        CGSize(
            width: zoomAnchor.x * size.width * (1 - zoomScale),
            height: zoomAnchor.y * size.height * (1 - zoomScale)
        )
    }

    private func clampedTotalOffset(_ offset: CGSize, scale: CGFloat, size: CGSize) -> CGSize {
        let minX = size.width * (1 - scale)
        let minY = size.height * (1 - scale)
        return CGSize(
            width: min(0, max(minX, offset.width)),
            height: min(0, max(minY, offset.height))
        )
    }

    @ViewBuilder
    private func content(mode: ZoomMode, size: CGSize) -> some View {
        switch mode {
        case .smartFit:
            fitScreenContent(size: size)
        case .fitScreen:
            fitScreenContent(size: size)
        case .fitWidth:
            ScrollView(.vertical, showsIndicators: false) {
                PageImage(loader: page.loader, maxPixelSize: renderPixelSize(in: size))
                    .scaledToFit()
                    .frame(width: max(size.width, 1), alignment: .top)
            }
        case .originalSize:
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                PageImage(loader: page.loader, maxPixelSize: renderPixelSize(in: page.loader.pointSize))
                    .scaledToFit()
                    .frame(
                        width: max(page.loader.pointSize.width, 1),
                        height: max(page.loader.pointSize.height, 1)
                    )
            }
        case .fillScreen:
            PageImage(loader: page.loader, maxPixelSize: renderPixelSize(in: size))
                .scaledToFill()
                .frame(width: max(size.width, 1), height: max(size.height, 1))
                .clipped()
        }
    }

    private func fitScreenContent(size: CGSize) -> some View {
        PageImage(loader: page.loader, maxPixelSize: renderPixelSize(in: size))
            .scaledToFit()
            .frame(width: max(size.width, 1), height: max(size.height, 1), alignment: .center)
    }

    private func renderPixelSize(in size: CGSize) -> CGFloat {
        let screenScale = NSScreen.main?.backingScaleFactor ?? 2
        let target = max(size.width, size.height) * screenScale
        let rounded = ceil(target / 256) * 256
        return min(3072, max(1280, rounded))
    }
}

