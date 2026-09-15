import AppKit
import Foundation
import UniformTypeIdentifiers

enum TranscriptFileStore {
    @MainActor
    static func saveAlongsideSource(
        markdown: String,
        sourceURL: URL,
        fileName: String
    ) throws -> URL {
        let directory = sourceURL.deletingLastPathComponent()
        let destination = directory.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: destination.path) {
            throw TranscriptionError.saveFailed("Ya existe \(fileName) junto al vídeo. Usa «Guardar como…».")
        }
        try write(markdown, to: destination)
        return destination
    }

    @MainActor
    static func saveWithPanel(markdown: String, suggestedFileName: String) throws -> URL? {
        let panel = NSSavePanel()
        panel.title = "Guardar transcripción"
        panel.message = "Elige dónde guardar el Markdown."
        panel.nameFieldStringValue = suggestedFileName
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        if let markdownType = UTType(filenameExtension: "md") {
            panel.allowedContentTypes = [markdownType]
        } else {
            panel.allowedContentTypes = [.plainText]
        }

        guard panel.runModal() == .OK, let url = panel.url else {
            return nil
        }

        try write(markdown, to: url)
        return url
    }

    static func write(_ markdown: String, to url: URL) throws {
        do {
            try markdown.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw TranscriptionError.saveFailed(error.localizedDescription)
        }
    }

    @MainActor
    static func copyToPasteboard(_ markdown: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(markdown, forType: .string)
    }

    @MainActor
    static func openPanel() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Abrir vídeo o audio"
        panel.message = "Elige un archivo MP4, MOV, M4V o un audio compatible."
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = SupportedMedia.allowedContentTypes
        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }
}
