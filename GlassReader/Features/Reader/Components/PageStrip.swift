import AppKit
import ImageIO
import PDFKit
import SwiftUI

struct PageStrip: View {
    @EnvironmentObject private var library: ReaderLibrary
    @State private var sliderValue = 0.0
    var compact = false

    var body: some View {
        if library.pages.isEmpty {
            EmptyView()
        } else if library.pageCount <= 1 {
            Capsule()
                .fill(.secondary.opacity(0.2))
                .frame(height: 6)
        } else {
            FlatProgressSlider(
                value: sliderValue,
                range: 0...Double(library.pageCount - 1),
                step: 1,
                isRightToLeft: library.readingDirection == .rightToLeft,
                onEditingChanged: { editing in
                    if editing {
                        sliderValue = Double(library.currentIndex)
                    }
                },
                onChange: { value in
                    jumpWithoutAnimation(to: Int(value.rounded()))
                }
            )
            .frame(height: 24)
            .onAppear {
                sliderValue = Double(library.currentIndex)
            }
            .onChange(of: library.currentIndex) { _, newValue in
                sliderValue = Double(newValue)
            }
        }
    }

    private func jumpWithoutAnimation(to index: Int) {
        var transaction = Transaction()
        transaction.animation = nil
        withTransaction(transaction) {
            library.jump(to: index)
        }
    }
}

