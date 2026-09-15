import AVFoundation
import Foundation

struct PreparedAudio: Sendable {
    let audioURL: URL
    let duration: TimeInterval
    let sourceFileName: String
    let sourcePath: String
    let ownsFile: Bool
}

enum MediaAudioExtractor {
    static func sweepTemporaryFiles() {
        let directory = FileManager.default.temporaryDirectory
        guard let items = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else { return }
        for item in items where item.lastPathComponent.hasPrefix("transcribir-") {
            try? FileManager.default.removeItem(at: item)
        }
    }

    static func prepare(url: URL) async throws -> PreparedAudio {
        _ = try SupportedMedia.validate(url)
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let workingURL = try copyToTemporaryLocation(from: url)
        var keepWorkingCopy = false
        defer {
            if !keepWorkingCopy {
                try? FileManager.default.removeItem(at: workingURL)
            }
        }

        let asset = AVURLAsset(url: workingURL)
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        guard !audioTracks.isEmpty else {
            throw TranscriptionError.noAudioTrack
        }

        let duration = durationSeconds(from: try await asset.load(.duration))

        if canOpenAsAudioFile(workingURL) {
            keepWorkingCopy = true
            return PreparedAudio(
                audioURL: workingURL,
                duration: duration,
                sourceFileName: url.lastPathComponent,
                sourcePath: url.path,
                ownsFile: true
            )
        }

        let exported = try await exportM4A(from: asset)
        return PreparedAudio(
            audioURL: exported,
            duration: duration,
            sourceFileName: url.lastPathComponent,
            sourcePath: url.path,
            ownsFile: true
        )
    }

    static func cleanup(_ prepared: PreparedAudio) {
        guard prepared.ownsFile else { return }
        try? FileManager.default.removeItem(at: prepared.audioURL)
    }

    private static func copyToTemporaryLocation(from url: URL) throws -> URL {
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("transcribir-\(UUID().uuidString)")
            .appendingPathExtension(url.pathExtension)
        do {
            try FileManager.default.copyItem(at: url, to: destination)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: destination.path
            )
            return destination
        } catch {
            try? FileManager.default.removeItem(at: destination)
            throw TranscriptionError.failedToAccessFile
        }
    }

    private static func canOpenAsAudioFile(_ url: URL) -> Bool {
        do {
            _ = try AVAudioFile(forReading: url)
            return true
        } catch {
            return false
        }
    }

    private static func exportM4A(from asset: AVAsset) async throws -> URL {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("transcribir-audio-\(UUID().uuidString)")
            .appendingPathExtension("m4a")

        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw TranscriptionError.failedToPrepareAudio
        }

        do {
            try await session.export(to: outputURL, as: .m4a)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: outputURL.path
            )
            return outputURL
        } catch {
            try? FileManager.default.removeItem(at: outputURL)
            throw TranscriptionError.failedToPrepareAudio
        }
    }

    private static func durationSeconds(from time: CMTime) -> TimeInterval {
        guard time.isValid, !time.isIndefinite else { return 0 }
        let seconds = time.seconds
        return seconds.isFinite ? max(0, seconds) : 0
    }
}
