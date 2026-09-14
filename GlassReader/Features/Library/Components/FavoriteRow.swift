import AppKit
import ImageIO
import PDFKit
import SwiftUI

struct FavoriteRow: View {
    @EnvironmentObject private var library: ReaderLibrary
    let item: FavoriteItem
    let openAction: () -> Void
    let removeAction: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .lineLimit(1)
                    .font(.subheadline.weight(.medium))
                Text(item.path)
                    .lineLimit(1)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if item.pageCount > 0 {
                    Text(library.format(.lastRead, "\(item.lastPageIndex + 1)", "\(item.pageCount)"))
                        .lineLimit(1)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                openAction()
            }

            Button(action: removeAction) {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

