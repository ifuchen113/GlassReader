import AppKit
import ImageIO
import PDFKit
import SwiftUI

struct ArchivePasswordView: View {
    @EnvironmentObject private var library: ReaderLibrary
    let prompt: ArchivePasswordPrompt
    @State private var password = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(library.t(.passwordTitle))
                    .font(.title3.weight(.semibold))
                Text(prompt.url.lastPathComponent)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(prompt.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            SecureField(library.t(.passwordPlaceholder), text: $password)
                .textFieldStyle(.roundedBorder)
                .onSubmit(openWithPassword)

            HStack {
                Spacer()
                Button(library.t(.cancel)) {
                    library.cancelArchivePassword()
                }
                Button(library.t(.open)) {
                    openWithPassword()
                }
                .buttonStyle(.borderedProminent)
                .disabled(password.isEmpty)
            }
        }
        .padding(22)
        .frame(width: 380)
    }

    private func openWithPassword() {
        guard !password.isEmpty else { return }
        library.submitArchivePassword(prompt, password: password)
    }
}
