import AppKit
import ImageIO
import PDFKit
import SwiftUI

struct ToolbarPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.primary)
            .frame(minWidth: 34)
            .frame(height: 28)
            .padding(.horizontal, 2)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(configuration.isPressed ? Color.primary.opacity(0.16) : Color.primary.opacity(0.08))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

struct PageModeGlyph: View {
    let pageCount: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(.primary, lineWidth: 1.6)
                .frame(width: 20, height: 16)
            Text("\(pageCount)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
        }
        .frame(width: 24, height: 20)
    }
}

struct DirectionModeGlyph: View {
    let direction: ReadingDirection

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(.primary, lineWidth: 1.6)
                .frame(width: 22, height: 16)
            Image(systemName: direction == .leftToRight ? "arrow.right" : "arrow.left")
                .font(.system(size: 11, weight: .bold))
        }
        .frame(width: 24, height: 20)
    }
}

