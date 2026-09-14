import AppKit
import ImageIO
import PDFKit
import SwiftUI

struct TabBarView: View {
    @EnvironmentObject private var library: ReaderLibrary
    let leadingPadding: CGFloat

    var body: some View {
        HStack(spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(library.tabs) { tab in
                        HStack(spacing: 6) {
                            Button {
                                library.activateTab(tab)
                            } label: {
                                Text(tab.name)
                                    .font(.caption.weight(.medium))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .frame(minWidth: 92, maxWidth: 190, alignment: .leading)
                            }
                            .buttonStyle(.plain)

                            Button {
                                library.closeTab(tab.id)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .semibold))
                                    .frame(width: 18, height: 18)
                            }
                            .buttonStyle(.plain)
                            .help("关闭 \(tab.name)")
                        }
                        .padding(.horizontal, 9)
                        .frame(height: 28)
                        .background(
                            library.activeTabID == tab.id
                                ? AnyShapeStyle(.tint.opacity(0.18))
                                : AnyShapeStyle(Color.primary.opacity(0.06)),
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .onTapGesture {
                            library.activateTab(tab)
                        }
                    }
                }
                .padding(.vertical, 1)
            }

            Button {
                library.openWithPanel()
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(ToolbarPillButtonStyle())
            .help(library.t(.openLocalFile))
        }
        .padding(.leading, leadingPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

