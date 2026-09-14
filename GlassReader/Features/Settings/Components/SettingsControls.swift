import AppKit
import ImageIO
import PDFKit
import SwiftUI

struct ViewSettingRow<Control: View>: View {
    let title: String
    @ViewBuilder var control: Control

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, alignment: .leading)
            control
                .frame(width: sidebarSettingControlWidth, alignment: .trailing)
        }
    }
}

struct SidebarFixedDropdown<Option: Hashable>: View {
    let title: String
    let options: [Option]
    let optionTitle: (Option) -> String
    let select: (Option) -> Void

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(optionTitle(option)) {
                    select(option)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity, alignment: .center)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.horizontal, 10)
            .frame(width: sidebarSettingControlWidth, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.primary.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }
}

