import AppKit
import ImageIO
import PDFKit
import SwiftUI

struct ScrollWheelPagingMonitor: NSViewRepresentable {
    let handlesPaging: Bool
    let onPreviousPage: () -> Void
    let onNextPage: () -> Void
    let onZoom: (CGFloat, CGPoint) -> Void
    let onResetZoom: (CGPoint) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            handlesPaging: handlesPaging,
            onPreviousPage: onPreviousPage,
            onNextPage: onNextPage,
            onZoom: onZoom,
            onResetZoom: onResetZoom
        )
    }

    func makeNSView(context: Context) -> MonitorView {
        let view = MonitorView()
        context.coordinator.view = view
        context.coordinator.installMonitor()
        return view
    }

    func updateNSView(_ nsView: MonitorView, context: Context) {
        context.coordinator.handlesPaging = handlesPaging
        context.coordinator.onPreviousPage = onPreviousPage
        context.coordinator.onNextPage = onNextPage
        context.coordinator.onZoom = onZoom
        context.coordinator.onResetZoom = onResetZoom
    }

    static func dismantleNSView(_ nsView: MonitorView, coordinator: Coordinator) {
        coordinator.removeMonitor()
    }

    final class MonitorView: NSView {
        override func hitTest(_ point: NSPoint) -> NSView? {
            nil
        }
    }

    @MainActor
    final class Coordinator {
        // SwiftUI can briefly keep the previous representable alive while a tab changes.
        // Only the newest reader monitor may consume window-local input during that handoff.
        private static weak var activeCoordinator: Coordinator?

        weak var view: NSView?
        var handlesPaging: Bool
        var onPreviousPage: () -> Void
        var onNextPage: () -> Void
        var onZoom: (CGFloat, CGPoint) -> Void
        var onResetZoom: (CGPoint) -> Void

        private var eventMonitor: Any?
        private var accumulatedDeltaY: CGFloat = 0
        private var lastDirection = 0
        private var didTriggerPreciseGesture = false
        private var lastDiscreteTriggerTime: TimeInterval = 0
        private var mouseDownPoint: CGPoint?
        private var didDragMouse = false

        static func currentMouseLocation() -> CGPoint? {
            guard let view = activeCoordinator?.view,
                  let window = view.window else {
                return nil
            }
            return view.convert(window.mouseLocationOutsideOfEventStream, from: nil)
        }

        init(
            handlesPaging: Bool,
            onPreviousPage: @escaping () -> Void,
            onNextPage: @escaping () -> Void,
            onZoom: @escaping (CGFloat, CGPoint) -> Void,
            onResetZoom: @escaping (CGPoint) -> Void
        ) {
            self.handlesPaging = handlesPaging
            self.onPreviousPage = onPreviousPage
            self.onNextPage = onNextPage
            self.onZoom = onZoom
            self.onResetZoom = onResetZoom
        }

        func installMonitor() {
            guard eventMonitor == nil else { return }
            Self.activeCoordinator = self
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [
                .scrollWheel,
                .leftMouseDown,
                .leftMouseDragged,
                .leftMouseUp,
                .rightMouseDown,
                .rightMouseDragged,
                .rightMouseUp
            ]) { [weak self] event in
                self?.handle(event) ?? event
            }
        }

        func removeMonitor() {
            guard let eventMonitor else { return }
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
            if Self.activeCoordinator === self {
                Self.activeCoordinator = nil
            }
        }

        private func handle(_ event: NSEvent) -> NSEvent? {
            guard Self.activeCoordinator === self else { return event }
            guard let view,
                  let window = view.window,
                  event.window === window else {
                return event
            }

            if event.type == .leftMouseDown || event.type == .rightMouseDown {
                let point = view.convert(event.locationInWindow, from: nil)
                guard view.bounds.contains(point) else { return event }
                mouseDownPoint = event.locationInWindow
                didDragMouse = false
                return event
            }

            if event.type == .leftMouseDragged || event.type == .rightMouseDragged {
                guard let mouseDownPoint else { return event }
                let dx = event.locationInWindow.x - mouseDownPoint.x
                let dy = event.locationInWindow.y - mouseDownPoint.y
                if hypot(dx, dy) > 4 {
                    didDragMouse = true
                }
                return event
            }

            if event.type == .leftMouseUp || event.type == .rightMouseUp {
                let point = view.convert(event.locationInWindow, from: nil)
                defer {
                    mouseDownPoint = nil
                    didDragMouse = false
                }
                guard view.bounds.contains(point), mouseDownPoint != nil else { return event }
                guard !didDragMouse else { return event }
                if event.type == .leftMouseUp {
                    onNextPage()
                } else {
                    onPreviousPage()
                }
                return event
            }

            guard view.bounds.contains(view.convert(event.locationInWindow, from: nil)) else {
                return event
            }

            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard abs(event.scrollingDeltaY) > abs(event.scrollingDeltaX) else {
                return event
            }

            if modifiers.contains(.command) {
                let amount = event.hasPreciseScrollingDeltas
                    ? event.scrollingDeltaY / 180
                    : event.scrollingDeltaY * 0.12
                let point = view.convert(event.locationInWindow, from: nil)
                onZoom(amount, point)
                return nil
            }

            guard handlesPaging, modifiers.isEmpty else { return event }

            if event.phase.contains(.began) {
                accumulatedDeltaY = 0
                didTriggerPreciseGesture = false
            }

            if !event.momentumPhase.isEmpty {
                return nil
            }

            let direction = event.scrollingDeltaY > 0 ? 1 : -1
            if direction != lastDirection {
                accumulatedDeltaY = 0
                didTriggerPreciseGesture = false
                lastDirection = direction
            }
            accumulatedDeltaY += event.scrollingDeltaY

            if event.hasPreciseScrollingDeltas {
                guard !didTriggerPreciseGesture, abs(accumulatedDeltaY) >= 28 else {
                    if event.phase.contains(.ended) || event.phase.contains(.cancelled) {
                        accumulatedDeltaY = 0
                        didTriggerPreciseGesture = false
                    }
                    return nil
                }
                didTriggerPreciseGesture = true
            } else {
                let now = ProcessInfo.processInfo.systemUptime
                guard abs(accumulatedDeltaY) >= 1,
                      now - lastDiscreteTriggerTime >= 0.28 else {
                    return nil
                }
                lastDiscreteTriggerTime = now
            }

            accumulatedDeltaY = 0
            if direction > 0 {
                onPreviousPage()
            } else {
                onNextPage()
            }
            return nil
        }
    }
}

