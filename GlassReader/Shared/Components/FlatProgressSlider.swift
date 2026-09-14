import AppKit
import ImageIO
import PDFKit
import SwiftUI

struct FlatProgressSlider: View {
    let value: Double
    let range: ClosedRange<Double>
    var step: Double = 1
    var isRightToLeft = false
    var onEditingChanged: (Bool) -> Void = { _ in }
    let onChange: (Double) -> Void

    @State private var draftValue: Double?
    @State private var isDragging = false

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let activeValue = clamped(draftValue ?? value)
            let progress = progress(for: activeValue)
            let thumbCenter = width * (isRightToLeft ? 1 - progress : progress)
            let fillOffset = isRightToLeft ? thumbCenter : 0
            let fillWidth = isRightToLeft ? width - thumbCenter : thumbCenter

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.secondary.opacity(0.22))
                    .frame(height: 6)
                Capsule()
                    .fill(.tint)
                    .frame(width: fillWidth, height: 6)
                    .offset(x: fillOffset)
                Circle()
                    .fill(.white)
                    .frame(width: 18, height: 18)
                    .shadow(color: .black.opacity(0.18), radius: 3, y: 1)
                    .offset(x: min(max(thumbCenter - 9, 0), max(width - 18, 0)))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        if !isDragging {
                            isDragging = true
                            onEditingChanged(true)
                        }
                        draftValue = valueFromDrag(x: drag.location.x, width: width)
                    }
                    .onEnded { drag in
                        let finalValue = valueFromDrag(x: drag.location.x, width: width)
                        draftValue = nil
                        isDragging = false
                        onChange(finalValue)
                        onEditingChanged(false)
                    }
            )
        }
    }

    private func clamped(_ rawValue: Double) -> Double {
        min(max(rawValue, range.lowerBound), range.upperBound)
    }

    private func progress(for rawValue: Double) -> Double {
        let span = max(range.upperBound - range.lowerBound, 1)
        return min(max((rawValue - range.lowerBound) / span, 0), 1)
    }

    private func valueFromDrag(x: CGFloat, width: CGFloat) -> Double {
        let rawProgress = min(max(x / max(width, 1), 0), 1)
        let progress = isRightToLeft ? 1 - rawProgress : rawProgress
        let rawValue = range.lowerBound + (range.upperBound - range.lowerBound) * Double(progress)
        guard step > 0 else { return clamped(rawValue) }
        let stepped = (rawValue / step).rounded() * step
        return clamped(stepped)
    }
}

