import AppKit
import ImageIO
import PDFKit
import SwiftUI

@MainActor
extension ReaderLibrary {
    func toggleFullScreen() {
        if isImmersiveMode {
            keepsTopOverlayOpen = false
            setReaderMode(focus: false, immersive: false)
            return
        }
        toggleWindowFullScreen()
    }

    func toggleFocusMode() {
        if isImmersiveMode {
            showsImmersiveSidebar.toggle()
            keepsTopOverlayOpen = showsImmersiveSidebar
            return
        }
        isFocusMode.toggle()
        if !isFocusMode {
            isImmersiveMode = false
        }
    }

    func enterImmersiveMode() {
        showsImmersiveSidebar = false
        if NSApp.keyWindow?.styleMask.contains(.fullScreen) == false {
            toggleWindowFullScreen(useSnapshot: true, prepareTransition: {
                self.setReaderMode(focus: true, immersive: true)
            })
        } else {
            setReaderMode(focus: true, immersive: true)
        }
    }

    func toggleImmersiveMode() {
        isImmersiveMode ? exitImmersiveMode() : enterImmersiveMode()
    }

    func exitImmersiveMode() {
        keepsTopOverlayOpen = false
        showsImmersiveSidebar = false
        if NSApp.keyWindow?.styleMask.contains(.fullScreen) == true {
            toggleWindowFullScreen(useSnapshot: true, afterTransition: {
                self.setReaderMode(focus: false, immersive: false)
            })
        } else {
            setReaderMode(focus: false, immersive: false)
        }
    }

    func toggleWindowFullScreen(
        useSnapshot: Bool = false,
        prepareTransition: (() -> Void)? = nil,
        afterTransition: (() -> Void)? = nil
    ) {
        guard let window = NSApp.keyWindow else { return }
        if useSnapshot {
            transitionSnapshot = captureWindowSnapshot(window)
        }
        prepareTransition?()
        DispatchQueue.main.asyncAfter(deadline: .now() + (useSnapshot ? 0.02 : 0)) {
            window.toggleFullScreen(nil)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.62) { [weak self] in
            afterTransition?()
            guard useSnapshot else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                self?.transitionSnapshot = nil
            }
        }
    }

    func captureWindowSnapshot(_ window: NSWindow) -> NSImage? {
        guard let contentView = window.contentView else { return nil }
        let bounds = contentView.bounds
        guard bounds.width > 0, bounds.height > 0,
              let representation = contentView.bitmapImageRepForCachingDisplay(in: bounds) else {
            return nil
        }
        contentView.cacheDisplay(in: bounds, to: representation)
        let image = NSImage(size: bounds.size)
        image.addRepresentation(representation)
        return image
    }

    func setReaderMode(focus: Bool, immersive: Bool) {
        var transaction = Transaction()
        transaction.animation = nil
        withTransaction(transaction) {
            isFocusMode = focus
            isImmersiveMode = immersive
        }
    }

}
