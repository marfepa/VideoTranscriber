import Foundation
import Speech
import Testing
@testable import TranscribirVideos

struct SpeechPipelineTests {
    @Test func extractsAudioFromSpokenM4A() async throws {
        let url = try fixture("hola", ext: "m4a")
        let prepared = try await MediaAudioExtractor.prepare(url: url)
        defer { MediaAudioExtractor.cleanup(prepared) }
        #expect(prepared.duration > 0.5)
        #expect(prepared.sourceFileName == "hola.m4a")
    }

    @Test func extractsAudioFromSpokenMP4() async throws {
        let url = try fixture("hola", ext: "mp4")
        let prepared = try await MediaAudioExtractor.prepare(url: url)
        defer { MediaAudioExtractor.cleanup(prepared) }
        #expect(prepared.duration > 0.5)
        #expect(try SupportedMedia.kind(for: url) == .video)
    }

    @Test func preparesSpokenMP3WhenPresent() async throws {
        let url = try fixture("hola", ext: "mp3")
        let prepared = try await MediaAudioExtractor.prepare(url: url)
        defer { MediaAudioExtractor.cleanup(prepared) }
        #expect(prepared.duration > 0.5)
        #expect(try SupportedMedia.validate(url) == .audio)
    }

    @Test func transcribesSpokenSpanishOnDevice() async throws {
        try #require(SpeechTranscriber.isAvailable)
        let url = try fixture("hola", ext: "m4a")
        let prepared = try await MediaAudioExtractor.prepare(url: url)
        defer { MediaAudioExtractor.cleanup(prepared) }

        let service = SpeechTranscriptionService()
        var locale = await service.resolvedLocale(matching: Locale(identifier: "es-ES"))
        if locale == nil {
            locale = await service.resolvedLocale(matching: .current)
        }
        let resolved = try #require(locale)

        let segments = try await service.transcribe(prepared: prepared, locale: resolved) { _ in }
        let text = segments.map(\.text).joined(separator: " ").lowercased()
        #expect(!segments.isEmpty)
        #expect(text.contains("hola") || text.contains("prueba") || text.contains("transcrip"))
    }

    private func fixture(_ name: String, ext: String) throws -> URL {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
            .appendingPathComponent("\(name).\(ext)")
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw TranscriptionError.failedToAccessFile
        }
        return url
    }
}
