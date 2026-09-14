import AppKit
import ImageIO
import PDFKit
import SwiftUI

struct ReaderView: View {
    @EnvironmentObject private var library: ReaderLibrary
    @Binding var showsTopOverlay: Bool
    let sidebarIsDocked: Bool
    @State private var showsBottomOverlay = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                VStack(spacing: 0) {
                    if !library.isImmersiveMode {
                        ToolbarView()
                            .padding(.leading, toolbarLeadingPadding)
                            .padding(.trailing, 22)
                            .padding(.vertical, 14)

                        TabBarView(leadingPadding: tabBarLeadingPadding)
                            .padding(.trailing, 22)
                            .padding(.bottom, 8)
                    }

                    ZStack {
                        if library.pages.isEmpty {
                            EmptyReaderState()
                        } else {
                            SpreadStage()
                                .id(library.activeTabID)
                                .padding(.horizontal, library.isFocusMode ? 0 : 8)
                                .padding(.vertical, library.isFocusMode ? 0 : 6)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if !library.isFocusMode || (!library.isImmersiveMode && showsBottomOverlay) {
                        PageStrip(compact: library.isFocusMode)
                            .frame(height: library.isFocusMode ? 44 : 34)
                            .padding(.horizontal, library.isFocusMode ? 80 : 20)
                            .padding(.bottom, library.isFocusMode ? 18 : 10)
                            .background(library.isFocusMode ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(.clear))
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .top) {
                    if library.isImmersiveMode && showsTopOverlay {
                        VStack(spacing: 0) {
                            ToolbarView()
                                .padding(.leading, sidebarIsDocked ? 22 : 68)
                                .padding(.trailing, 22)
                                .padding(.vertical, 14)

                            TabBarView(leadingPadding: tabBarLeadingPadding)
                                .padding(.trailing, 22)
                                .padding(.bottom, 8)
                        }
                        .background(
                            library.isImmersiveMode
                                ? AnyShapeStyle(.ultraThinMaterial)
                                : AnyShapeStyle(.clear)
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(2)
                    }
                }
                .overlay(alignment: .bottom) {
                    if library.isImmersiveMode && showsBottomOverlay {
                        PageStrip(compact: true)
                            .frame(height: 44)
                            .padding(.horizontal, 80)
                            .padding(.bottom, 18)
                            .background(.ultraThinMaterial)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .zIndex(2)
                    }
                }
            }
            .onContinuousHover { phase in
                guard library.isFocusMode else { return }
                switch phase {
                case .active(let location):
                    if library.keepsTopOverlayOpen {
                        showsTopOverlay = true
                    } else if location.y < 112 {
                        showsTopOverlay = true
                    } else if location.y > 156 {
                        showsTopOverlay = false
                    }
                    showsBottomOverlay = location.y > proxy.size.height - 96
                case .ended:
                    showsBottomOverlay = false
                }
            }
            .onChange(of: library.keepsTopOverlayOpen) { _, keepOpen in
                if keepOpen {
                    showsTopOverlay = true
                }
            }
        }
        .animation(.easeOut(duration: 0.16), value: showsTopOverlay)
        .animation(.easeOut(duration: 0.16), value: showsBottomOverlay)
    }

    private var toolbarLeadingPadding: CGFloat {
        sidebarIsDocked ? 22 : 68
    }

    private var tabBarLeadingPadding: CGFloat {
        sidebarIsDocked ? 22 : 18
    }
}

