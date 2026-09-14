import AppKit
import ImageIO
import PDFKit
import SwiftUI

struct EmptyReaderState: View {
    @EnvironmentObject private var library: ReaderLibrary

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.pages")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(.secondary)
            Text(library.t(.emptyTitle))
                .font(.title2.weight(.medium))
                .multilineTextAlignment(.center)
            Text(library.t(.emptySubtitle))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                library.openWithPanel()
            } label: {
                Label(library.t(.chooseFile), systemImage: "folder.badge.plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(34)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct LiquidBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(nsColor: .windowBackgroundColor),
                Color(red: 0.86, green: 0.91, blue: 0.95),
                Color(red: 0.94, green: 0.94, blue: 0.90)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
