import AppKit
import ImageIO
import PDFKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var library: ReaderLibrary
    @State private var keyMonitor: Any?
    @State private var showsEdgeSidebar = false
    @State private var showsTopOverlay = true

    var body: some View {
        ZStack(alignment: .topLeading) {
            LiquidBackground()
            HStack(spacing: 0) {
                if (!library.isFocusMode && !library.isImmersiveMode)
                    || showsEdgeSidebar
                    || library.showsImmersiveSidebar {
                    SidebarView()
                        .frame(width: sidebarWidth)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    Divider()
                        .opacity(0.35)
                }
                ReaderView(
                    showsTopOverlay: $showsTopOverlay,
                    sidebarIsDocked: sidebarIsDocked
                )
                    .clipped()
                    .zIndex(1)
            }

            if !library.isImmersiveMode || showsTopOverlay {
                Button {
                    library.toggleFocusMode()
                } label: {
                    Image(systemName: sidebarButtonSymbol)
                }
                .buttonStyle(ToolbarPillButtonStyle())
                .help(sidebarButtonHelp)
                .padding(.leading, 18)
                .padding(.top, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(8)
            }

            if let snapshot = library.transitionSnapshot {
                Image(nsImage: snapshot)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.identity)
                    .zIndex(20)
            }
        }
        .sheet(item: $library.archivePasswordPrompt) { prompt in
            ArchivePasswordView(prompt: prompt)
                .environmentObject(library)
        }
        .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
            library.openDroppedItemProviders(providers)
        }
        .onContinuousHover { phase in
            guard library.isFocusMode || library.isImmersiveMode else {
                if showsEdgeSidebar {
                    withAnimation(.easeOut(duration: 0.16)) {
                        showsEdgeSidebar = false
                    }
                }
                return
            }

            switch phase {
            case .active(let location):
                let hotZoneWidth: CGFloat = 24
                let shouldShow = showsEdgeSidebar
                    ? location.x < sidebarWidth
                    : location.x < hotZoneWidth
                if showsEdgeSidebar != shouldShow {
                    withAnimation(.easeOut(duration: 0.16)) {
                        showsEdgeSidebar = shouldShow
                    }
                }
            case .ended:
                withAnimation(.easeOut(duration: 0.16)) {
                    showsEdgeSidebar = false
                }
            }
        }
        .onChange(of: library.isFocusMode) { _, isFocusMode in
            if !isFocusMode && !library.isImmersiveMode {
                showsEdgeSidebar = false
            }
        }
        .onChange(of: library.isImmersiveMode) { _, isImmersiveMode in
            showsTopOverlay = isImmersiveMode ? library.keepsTopOverlayOpen : true
            if !isImmersiveMode {
                showsEdgeSidebar = false
            }
        }
        .onChange(of: library.keepsTopOverlayOpen) { _, keepOpen in
            if keepOpen {
                showsTopOverlay = true
            }
        }
        .onAppear {
            library.restorePersistedTabsIfNeeded()
            guard keyMonitor == nil else { return }
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if library.archivePasswordPrompt != nil {
                    return event
                }
                if NSApp.keyWindow?.firstResponder is NSTextView {
                    return event
                }
                return library.handleKeyEvent(event) ? nil : event
            }
        }
        .onDisappear {
            if let keyMonitor {
                NSEvent.removeMonitor(keyMonitor)
            }
            keyMonitor = nil
        }
        .animation(.easeOut(duration: 0.16), value: showsTopOverlay)
    }

    private var sidebarIsDocked: Bool {
        (!library.isFocusMode && !library.isImmersiveMode)
            || showsEdgeSidebar
            || library.showsImmersiveSidebar
    }

    private var sidebarButtonSymbol: String {
        if library.isImmersiveMode {
            return library.showsImmersiveSidebar ? "rectangle.inset.filled" : "sidebar.leading"
        }
        return library.isFocusMode ? "sidebar.leading" : "rectangle.inset.filled"
    }

    private var sidebarButtonHelp: String {
        if library.isImmersiveMode {
            return library.showsImmersiveSidebar ? library.t(.hideSidebar) : library.t(.showSidebar)
        }
        return library.isFocusMode ? library.t(.showSidebar) : library.t(.hideSidebar)
    }
}

