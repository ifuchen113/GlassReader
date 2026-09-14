import AppKit
import ImageIO
import PDFKit
import SwiftUI

struct SpreadStage: View {
    @EnvironmentObject private var library: ReaderLibrary
    @State private var zoomScales: [UUID: CGFloat] = [:]
    @State private var zoomAnchors: [UUID: UnitPoint] = [:]
    @State private var zoomOffsets: [UUID: CGSize] = [:]
    @State private var zoomedPageID: UUID?

    var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height
            let pages = library.visiblePages
            let usesScrollableImageMode = pages.contains { page in
                let mode = library.zoomMode.resolved(forAspectRatio: page.loader.aspectRatio)
                return mode == .fitWidth || mode == .originalSize
            }
            let totalWidth = pages.reduce(CGFloat.zero) {
                $0 + pageWidth($1, stageSize: proxy.size, visibleCount: pages.count)
            }

            HStack(spacing: 0) {
                ForEach(pages) { page in
                    PageSurface(
                        page: page,
                        zoomScale: zoomedPageID == page.id ? (zoomScales[page.id] ?? 1) : 1,
                        zoomAnchor: zoomAnchors[page.id] ?? .center,
                        panOffset: Binding(
                            get: { zoomOffsets[page.id] ?? .zero },
                            set: { zoomOffsets[page.id] = $0 }
                        )
                    )
                        .frame(
                            width: pageWidth(page, stageSize: proxy.size, visibleCount: pages.count),
                            height: height
                        )
                        .overlay(alignment: .bottomTrailing) {
                            if library.showsPageBadges, let index = library.displayIndex(for: page) {
                                Text("\(index)")
                                    .font(.caption.monospacedDigit())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.ultraThinMaterial, in: Capsule())
                                    .padding(10)
                            }
                        }
                }
            }
            .frame(width: totalWidth, height: height)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
            .overlay {
                ScrollWheelPagingMonitor(
                    handlesPaging: !usesScrollableImageMode,
                    onPreviousPage: library.previousPage,
                    onNextPage: library.nextPage,
                    onZoom: { amount, location in
                        zoomPage(at: location, amount: amount, stageSize: proxy.size, pages: pages)
                    },
                    onResetZoom: { location in
                        resetZoom(at: location, stageSize: proxy.size, pages: pages)
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onReceive(NotificationCenter.default.publisher(for: .glassReaderZoomOut)) { _ in
                zoomPage(
                    at: currentZoomLocation(in: proxy.size),
                    amount: -0.15,
                    stageSize: proxy.size,
                    pages: pages
                )
            }
            .onReceive(NotificationCenter.default.publisher(for: .glassReaderZoomIn)) { _ in
                zoomPage(
                    at: currentZoomLocation(in: proxy.size),
                    amount: 0.15,
                    stageSize: proxy.size,
                    pages: pages
                )
            }
            .onReceive(NotificationCenter.default.publisher(for: .glassReaderZoomReset)) { _ in
                resetZoom(
                    at: currentZoomLocation(in: proxy.size),
                    stageSize: proxy.size,
                    pages: pages
                )
            }
            .onChange(of: library.currentIndex) { _, _ in
                resetAllZoom()
            }
        }
    }

    private func resetAllZoom() {
        zoomScales.removeAll()
        zoomAnchors.removeAll()
        zoomOffsets.removeAll()
        zoomedPageID = nil
    }

    private func currentZoomLocation(in size: CGSize) -> CGPoint {
        ScrollWheelPagingMonitor.Coordinator.currentMouseLocation()
            ?? CGPoint(x: size.width / 2, y: size.height / 2)
    }

    private func zoomPage(
        at location: CGPoint,
        amount: CGFloat,
        stageSize: CGSize,
        pages: [ReaderPage]
    ) {
        guard !pages.isEmpty else { return }

        let totalWidth = pages.reduce(CGFloat.zero) {
            $0 + pageWidth($1, stageSize: stageSize, visibleCount: pages.count)
        }
        let stageOriginX = (stageSize.width - totalWidth) / 2
        var pageOriginX: CGFloat = stageOriginX
        for page in pages {
            let width = pageWidth(page, stageSize: stageSize, visibleCount: pages.count)
            let pageFrame = CGRect(x: pageOriginX, y: 0, width: width, height: stageSize.height)
            if pageFrame.contains(location) {
                // A spread may show two pages, but zoom belongs to one page only.
                // Clear the other page's transient zoom before applying this change.
                for otherPage in pages where otherPage.id != page.id {
                    zoomScales[otherPage.id] = 1
                    zoomAnchors[otherPage.id] = .center
                    zoomOffsets[otherPage.id] = .zero
                }
                zoomedPageID = page.id

                let anchor = UnitPoint(
                    x: min(1, max(0, (location.x - pageFrame.minX) / max(pageFrame.width, 1))),
                    y: min(1, max(0, location.y / max(pageFrame.height, 1)))
                )
                let oldScale = zoomScales[page.id] ?? 1
                let newScale = min(4, max(1, oldScale * (1 + amount)))
                let size = pageFrame.size
                let oldBaseOffset = baseOffset(
                    scale: oldScale,
                    anchor: zoomAnchors[page.id] ?? .center,
                    size: size
                )
                let oldPanOffset = zoomOffsets[page.id] ?? .zero
                let oldTotalOffset = CGSize(
                    width: oldBaseOffset.width + oldPanOffset.width,
                    height: oldBaseOffset.height + oldPanOffset.height
                )
                let localPoint = CGPoint(
                    x: location.x - pageFrame.minX,
                    y: location.y - pageFrame.minY
                )
                let cursorScreenPoint = CGPoint(
                    x: localPoint.x * oldScale + oldTotalOffset.width,
                    y: localPoint.y * oldScale + oldTotalOffset.height
                )
                let newBaseOffset = baseOffset(scale: newScale, anchor: anchor, size: size)
                let rawTotalOffset = CGSize(
                    width: cursorScreenPoint.x - localPoint.x * newScale,
                    height: cursorScreenPoint.y - localPoint.y * newScale
                )
                let clampedTotalOffset = clampedTotalOffset(
                    rawTotalOffset,
                    scale: newScale,
                    size: size
                )
                zoomAnchors[page.id] = anchor
                zoomScales[page.id] = newScale
                zoomOffsets[page.id] = newScale > 1
                    ? CGSize(
                        width: clampedTotalOffset.width - newBaseOffset.width,
                        height: clampedTotalOffset.height - newBaseOffset.height
                    )
                    : .zero
                return
            }
            pageOriginX += width
        }
    }

    private func resetZoom(at location: CGPoint, stageSize: CGSize, pages: [ReaderPage]) {
        let totalWidth = pages.reduce(CGFloat.zero) {
            $0 + pageWidth($1, stageSize: stageSize, visibleCount: pages.count)
        }
        let stageOriginX = (stageSize.width - totalWidth) / 2
        var pageOriginX = stageOriginX
        for page in pages {
            let width = pageWidth(page, stageSize: stageSize, visibleCount: pages.count)
            let pageFrame = CGRect(x: pageOriginX, y: 0, width: width, height: stageSize.height)
            if pageFrame.contains(location) {
                zoomScales[page.id] = 1
                zoomAnchors[page.id] = .center
                zoomOffsets[page.id] = .zero
                if zoomedPageID == page.id {
                    zoomedPageID = nil
                }
                return
            }
            pageOriginX += width
        }
    }

    private func baseOffset(scale: CGFloat, anchor: UnitPoint, size: CGSize) -> CGSize {
        CGSize(
            width: anchor.x * size.width * (1 - scale),
            height: anchor.y * size.height * (1 - scale)
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

    private func pageWidth(_ page: ReaderPage, stageSize: CGSize, visibleCount: Int) -> CGFloat {
        let slotWidth = max(1, stageSize.width / CGFloat(max(visibleCount, 1)))
        let aspect = page.loader.aspectRatio
        switch library.zoomMode.resolved(forAspectRatio: aspect) {
        case .smartFit:
            return slotWidth
        case .fitScreen:
            return max(1, stageSize.height * aspect)
        case .fitWidth:
            return slotWidth
        case .originalSize:
            return max(1, page.loader.pointSize.width)
        case .fillScreen:
            return slotWidth
        }
    }
}

