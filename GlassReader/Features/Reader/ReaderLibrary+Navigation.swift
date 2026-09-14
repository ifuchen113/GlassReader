import AppKit
import ImageIO
import PDFKit
import SwiftUI

@MainActor
extension ReaderLibrary {
    func nextPage() {
        guard !pages.isEmpty else { return }
        currentIndex = clamped(currentIndex + (isDoublePage ? 2 : 1))
        saveCurrentReadingProgress()
        restartSlideshowTimer()
    }

    func previousPage() {
        guard !pages.isEmpty else { return }
        currentIndex = clamped(currentIndex - (isDoublePage ? 2 : 1))
        saveCurrentReadingProgress()
        restartSlideshowTimer()
    }

    func turnLeft() {
        readingDirection == .rightToLeft ? nextPage() : previousPage()
    }

    func turnRight() {
        readingDirection == .rightToLeft ? previousPage() : nextPage()
    }

    func toggleReadingDirection() {
        setReadingDirection(readingDirection == .leftToRight ? .rightToLeft : .leftToRight)
    }

    func setReadingDirection(_ direction: ReadingDirection) {
        readingDirection = direction
        saveCurrentReadingProgress()
    }

    func toggleDoublePageMode() {
        isDoublePage.toggle()
        saveCurrentReadingProgress()
    }

    func rematchSpreadForward() {
        guard pages.count > 1 else { return }
        currentIndex = clamped(currentIndex + 1)
        status = format(.rematchedSpread, "\(currentIndex + 1)")
        saveCurrentReadingProgress()
        restartSlideshowTimer()
    }

    func rematchSpreadBackward() {
        guard pages.count > 1 else { return }
        currentIndex = clamped(currentIndex - 1)
        status = format(.rematchedSpread, "\(currentIndex + 1)")
        saveCurrentReadingProgress()
        restartSlideshowTimer()
    }

    func rematchSpreadLeft() {
        readingDirection == .rightToLeft ? rematchSpreadForward() : rematchSpreadBackward()
    }

    func rematchSpreadRight() {
        readingDirection == .rightToLeft ? rematchSpreadBackward() : rematchSpreadForward()
    }

    func jump(to index: Int) {
        currentIndex = clamped(index)
        saveCurrentReadingProgress()
        restartSlideshowTimer()
    }

    func toggleSlideshow() {
        isSlideshowRunning ? stopSlideshow() : startSlideshow()
    }

    func startSlideshow() {
        guard !pages.isEmpty else { return }
        stopSlideshow()
        isSlideshowRunning = true
        scheduleSlideshowTimer()
    }

    func scheduleSlideshowTimer() {
        slideshowTimer = Timer.scheduledTimer(withTimeInterval: slideshowInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.nextPage()
            }
        }
    }

    func restartSlideshowTimer() {
        guard isSlideshowRunning else { return }
        slideshowTimer?.invalidate()
        scheduleSlideshowTimer()
    }

    func stopSlideshow() {
        slideshowTimer?.invalidate()
        slideshowTimer = nil
        isSlideshowRunning = false
    }

    func updateSlideshowInterval(_ interval: Double) {
        slideshowInterval = interval
        if isSlideshowRunning {
            startSlideshow()
        }
    }

    func displayIndex(for page: ReaderPage) -> Int? {
        pages.firstIndex(of: page).map { $0 + 1 }
    }

    func page(at index: Int) -> ReaderPage? {
        guard pages.indices.contains(index) else { return nil }
        return pages[index]
    }

    func clamped(_ index: Int) -> Int {
        min(max(index, 0), max(pages.count - 1, 0))
    }

    func keyName(for event: NSEvent) -> String {
        switch event.keyCode {
        case 49:
            return "Space"
        case 53:
            return "Esc"
        case 123:
            return "←"
        case 124:
            return "→"
        case 125:
            return "↓"
        case 126:
            return "↑"
        default:
            return (event.charactersIgnoringModifiers ?? "").uppercased()
        }
    }

    nonisolated static func fileURL(fromDroppedItem item: NSSecureCoding?) -> URL? {
        if let url = item as? URL {
            return url
        }

        let rawString: String?
        if let data = item as? Data {
            rawString = String(data: data, encoding: .utf8)
        } else if let string = item as? String {
            rawString = string
        } else {
            rawString = nil
        }

        guard let cleaned = rawString?
            .replacingOccurrences(of: "\0", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !cleaned.isEmpty else {
            return nil
        }

        if let url = URL(string: cleaned), url.isFileURL {
            return url
        }

        return URL(fileURLWithPath: cleaned)
    }

}
