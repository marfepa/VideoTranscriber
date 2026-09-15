import Foundation
import UniformTypeIdentifiers

enum SupportedMedia {
    enum Kind: Equatable, Sendable {
        case video
        case audio
    }

    static let videoExtensions: Set<String> = ["mp4", "mov", "m4v", "3gp", "3g2"]
    static let audioExtensions: Set<String> = ["m4a", "wav", "caf", "mp3", "aiff", "aif", "aac"]
    static let unsupportedExtensions: Set<String> = ["mkv", "webm", "avi", "wmv", "flv", "ogv", "mpeg", "mpg"]

    static var allowedContentTypes: [UTType] {
        var types: [UTType] = [
            .mpeg4Movie,
            .quickTimeMovie,
            .mpeg4Audio,
            .wav,
            .aiff,
            .mp3
        ]
        types.append(contentsOf: [
            UTType(filenameExtension: "m4v"),
            UTType(filenameExtension: "caf"),
            UTType(filenameExtension: "3gp"),
            UTType(filenameExtension: "3g2"),
            UTType(filenameExtension: "aac")
        ].compactMap { $0 })
        return types
    }

    static func kind(for url: URL) throws -> Kind {
        let ext = url.pathExtension.lowercased()
        if videoExtensions.contains(ext) { return .video }
        if audioExtensions.contains(ext) { return .audio }
        if unsupportedExtensions.contains(ext) {
            throw TranscriptionError.unsupportedContainer(ext)
        }
        if ext.isEmpty {
            throw TranscriptionError.unsupportedContainer("sin extensión")
        }
        throw TranscriptionError.unsupportedContainer(ext)
    }

    static func validate(_ url: URL) throws -> Kind {
        guard url.isFileURL else {
            throw TranscriptionError.failedToAccessFile
        }
        let values: URLResourceValues
        do {
            values = try url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey])
        } catch {
            throw TranscriptionError.failedToAccessFile
        }
        guard values.isRegularFile == true, values.isDirectory != true else {
            throw TranscriptionError.failedToAccessFile
        }
        return try kind(for: url)
    }
}
