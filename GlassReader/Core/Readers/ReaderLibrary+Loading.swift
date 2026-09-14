import AppKit
import ImageIO
import PDFKit
import SwiftUI

@MainActor
extension ReaderLibrary {
    func loadPages(from url: URL, passwords: [String: String] = [:]) async throws -> [ReaderPage] {
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)

        if isDirectory.boolValue {
            return try collectPages(in: url)
        }

        let ext = url.pathExtension.lowercased()
        if ext == "pdf" {
            return try collectPDFPages(url)
        }
        if supportedImages.contains(ext) {
            return [ReaderPage(displayName: url.lastPathComponent, sourceURL: url, sortKey: url.path, loader: .image(url))]
        }
        if supportedArchives.contains(ext) {
            return try await loadArchivePages(
                from: url,
                passwords: passwords,
                fallbackPassword: archivePassword(for: url, in: passwords),
                depth: 0
            )
        }
        throw ReaderError.unsupportedFile
    }

    func loadArchivePages(from url: URL, passwords: [String: String], fallbackPassword: String?, depth: Int) async throws -> [ReaderPage] {
        guard depth < 4 else { throw ReaderError.archiveExtractionFailed }
        let password = archivePassword(for: url, in: passwords) ?? fallbackPassword
        let extracted = try extractArchive(url, password: password)
        await MainActor.run { extractedFolders.append(extracted) }

        let pages = try collectPages(in: extracted)
        if !pages.isEmpty {
            return pages
        }

        let nestedArchives = try collectArchives(in: extracted)
        for archive in nestedArchives {
            do {
                let nestedPages = try await loadArchivePages(
                    from: archive,
                    passwords: passwords,
                    fallbackPassword: password,
                    depth: depth + 1
                )
                if !nestedPages.isEmpty {
                    return nestedPages
                }
            } catch ReaderError.archiveNeedsPassword(let targetURL) {
                throw ReaderError.archiveNeedsPassword(targetURL)
            } catch ReaderError.archiveExtractionFailed {
                continue
            } catch ReaderError.missingArchiveTool {
                continue
            }
        }

        throw ReaderError.archiveExtractionFailed
    }

    func archivePassword(for url: URL, in passwords: [String: String]) -> String? {
        passwords[url.path] ?? passwords[url.lastPathComponent]
    }

    func rememberArchivePassword(_ password: String, for url: URL, in passwords: inout [String: String]) {
        passwords[url.path] = password
        passwords[url.lastPathComponent] = password
    }

    func isSupportedArchive(_ url: URL) -> Bool {
        supportedArchives.contains(url.pathExtension.lowercased())
    }

    func collectPages(in folder: URL) throws -> [ReaderPage] {
        let keys: [URLResourceKey] = [.isDirectoryKey, .isRegularFileKey, .localizedNameKey]
        guard let enumerator = FileManager.default.enumerator(
            at: folder,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var collected: [ReaderPage] = []
        for case let fileURL as URL in enumerator {
            let values = try fileURL.resourceValues(forKeys: Set(keys))
            if values.isDirectory == true { continue }
            let ext = fileURL.pathExtension.lowercased()
            if supportedImages.contains(ext) {
                collected.append(ReaderPage(displayName: fileURL.lastPathComponent, sourceURL: fileURL, sortKey: fileURL.path, loader: .image(fileURL)))
            } else if ext == "pdf" {
                collected.append(contentsOf: try collectPDFPages(fileURL))
            }
        }

        return collected.sorted { lhs, rhs in
            lhs.sortKey.localizedStandardCompare(rhs.sortKey) == .orderedAscending
        }
    }

    func collectArchives(in folder: URL) throws -> [URL] {
        let keys: [URLResourceKey] = [.isDirectoryKey, .isRegularFileKey]
        guard let enumerator = FileManager.default.enumerator(
            at: folder,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var archives: [URL] = []
        for case let fileURL as URL in enumerator {
            let values = try fileURL.resourceValues(forKeys: Set(keys))
            if values.isDirectory == true { continue }
            if supportedArchives.contains(fileURL.pathExtension.lowercased()) {
                archives.append(fileURL)
            }
        }
        return archives.sorted {
            $0.path.localizedStandardCompare($1.path) == .orderedAscending
        }
    }

    func collectPDFPages(_ url: URL) throws -> [ReaderPage] {
        guard let document = PDFDocument(url: url) else { throw ReaderError.unreadablePDF }
        return (0..<document.pageCount).map { index in
            ReaderPage(
                displayName: "\(url.lastPathComponent) · \(index + 1)",
                sourceURL: url,
                sortKey: "\(url.path)#\(String(format: "%06d", index))",
                loader: .pdfPage(url, index)
            )
        }
    }

    func extractArchive(_ url: URL, password: String? = nil) throws -> URL {
        let ext = url.pathExtension.lowercased()
        let commands = try archiveCommands(for: ext, archive: url, password: password)
        var didTryCommand = false

        for command in commands {
            didTryCommand = true
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent("GlassReader-\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

            if runArchiveCommand(command, destination: destination) {
                return destination
            }

            try? FileManager.default.removeItem(at: destination)
        }

        if didTryCommand {
            throw ReaderError.archiveNeedsPassword(url)
        }
        throw ReaderError.missingArchiveTool(ext.uppercased())
    }

    func runArchiveCommand(_ command: (executable: String, arguments: [String]), destination: URL) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command.executable)
        process.arguments = command.arguments.map {
            $0.replacingOccurrences(of: "__DESTINATION__", with: destination.path)
        }
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return false
        }
        process.waitUntilExit()
        return process.terminationStatus == 0 && containsExtractedFiles(in: destination)
    }

    func archiveCommands(for ext: String, archive: URL, password: String?) throws -> [(executable: String, arguments: [String])] {
        let password = password?.isEmpty == false ? password : nil
        let bundledTools = bundledArchiveToolPaths()
        var commands: [(executable: String, arguments: [String])] = []

        if ext == "zip" || ext == "cbz" {
            if let password {
                if let unzip = firstExistingExecutable(bundledTools.unzip + ["/usr/bin/unzip", "/opt/homebrew/bin/unzip", "/usr/local/bin/unzip"]) {
                    commands.append((unzip, ["-P", password, "-qq", "-o", archive.path, "-d", "__DESTINATION__"]))
                }
                if let unar = firstExistingExecutable(bundledTools.unar + ["/opt/homebrew/bin/unar", "/usr/local/bin/unar", "/usr/bin/unar"]) {
                    commands.append((unar, ["-quiet", "-force-overwrite", "-password", password, "-output-directory", "__DESTINATION__", archive.path]))
                }
                if let sevenZip = firstExistingExecutable(bundledTools.sevenZip + ["/opt/homebrew/bin/7zz", "/opt/homebrew/bin/7z", "/usr/local/bin/7zz", "/usr/local/bin/7z"]) {
                    commands.append((sevenZip, ["x", "-y", "-p\(password)", "-o__DESTINATION__", archive.path]))
                }
            } else {
                commands.append(("/usr/bin/ditto", ["-x", "-k", archive.path, "__DESTINATION__"]))
                if let unzip = firstExistingExecutable(bundledTools.unzip + ["/usr/bin/unzip", "/opt/homebrew/bin/unzip", "/usr/local/bin/unzip"]) {
                    commands.append((unzip, ["-qq", "-o", archive.path, "-d", "__DESTINATION__"]))
                }
                if let unar = firstExistingExecutable(bundledTools.unar + ["/opt/homebrew/bin/unar", "/usr/local/bin/unar", "/usr/bin/unar"]) {
                    commands.append((unar, ["-quiet", "-force-overwrite", "-output-directory", "__DESTINATION__", archive.path]))
                }
                if let sevenZip = firstExistingExecutable(bundledTools.sevenZip + ["/opt/homebrew/bin/7zz", "/opt/homebrew/bin/7z", "/usr/local/bin/7zz", "/usr/local/bin/7z"]) {
                    commands.append((sevenZip, ["x", "-y", "-o__DESTINATION__", archive.path]))
                }
            }
            return commands
        }

        if let unar = firstExistingExecutable(bundledTools.unar + ["/opt/homebrew/bin/unar", "/usr/local/bin/unar", "/usr/bin/unar"]) {
            var arguments = ["-quiet", "-force-overwrite"]
            if let password {
                arguments += ["-password", password]
            }
            arguments += ["-output-directory", "__DESTINATION__", archive.path]
            commands.append((unar, arguments))
        }

        if let sevenZip = firstExistingExecutable(bundledTools.sevenZip + ["/opt/homebrew/bin/7zz", "/opt/homebrew/bin/7z", "/usr/local/bin/7zz", "/usr/local/bin/7z"]) {
            var arguments = ["x", "-y", "-o__DESTINATION__"]
            if let password {
                arguments.append("-p\(password)")
            }
            arguments.append(archive.path)
            commands.append((sevenZip, arguments))
        }

        if let bsdtar = firstExistingExecutable(bundledTools.bsdtar + ["/usr/bin/bsdtar", "/usr/bin/tar", "/opt/homebrew/bin/bsdtar", "/usr/local/bin/bsdtar"]) {
            commands.append((bsdtar, ["-xf", archive.path, "-C", "__DESTINATION__"]))
        }

        guard !commands.isEmpty else { throw ReaderError.missingArchiveTool(ext.uppercased()) }
        return commands
    }

    func containsExtractedFiles(in folder: URL) -> Bool {
        let keys: [URLResourceKey] = [.isDirectoryKey, .isRegularFileKey]
        guard let enumerator = FileManager.default.enumerator(
            at: folder,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else { return false }

        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: Set(keys)) else { continue }
            if values.isDirectory == true { continue }
            if values.isRegularFile == true {
                return true
            }
        }
        return false
    }

    func bundledArchiveToolPaths() -> (sevenZip: [String], unar: [String], unzip: [String], bsdtar: [String]) {
        let folders = [
            Bundle.main.resourceURL,
            Bundle.main.resourceURL?.appendingPathComponent("Tools", isDirectory: true),
            Bundle.main.bundleURL.appendingPathComponent("Contents/MacOS", isDirectory: true)
        ].compactMap { $0 }

        func paths(named names: [String]) -> [String] {
            folders.flatMap { folder in
                names.map { folder.appendingPathComponent($0).path }
            }
        }

        return (
            sevenZip: paths(named: ["7zz", "7z"]),
            unar: paths(named: ["unar"]),
            unzip: paths(named: ["unzip"]),
            bsdtar: paths(named: ["bsdtar", "tar"])
        )
    }

    func firstExistingExecutable(_ paths: [String]) -> String? {
        paths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

}
