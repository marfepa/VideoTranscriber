import Foundation
import Testing
@testable import TranscribirVideos

struct SupportedMediaTests {
    @Test func acceptsCommonAppleVideoContainers() throws {
        #expect(try SupportedMedia.kind(for: URL(fileURLWithPath: "/tmp/a.mp4")) == .video)
        #expect(try SupportedMedia.kind(for: URL(fileURLWithPath: "/tmp/a.mov")) == .video)
        #expect(try SupportedMedia.kind(for: URL(fileURLWithPath: "/tmp/a.m4v")) == .video)
    }

    @Test func acceptsCommonAudioContainers() throws {
        #expect(try SupportedMedia.kind(for: URL(fileURLWithPath: "/tmp/a.m4a")) == .audio)
        #expect(try SupportedMedia.kind(for: URL(fileURLWithPath: "/tmp/a.wav")) == .audio)
        #expect(try SupportedMedia.kind(for: URL(fileURLWithPath: "/tmp/a.mp3")) == .audio)
    }

    @Test func rejectsNonNativeContainersWithClearError() {
        do {
            _ = try SupportedMedia.kind(for: URL(fileURLWithPath: "/tmp/film.mkv"))
            Issue.record("Expected mkv to fail")
        } catch let error as TranscriptionError {
            #expect(error == .unsupportedContainer("mkv"))
            #expect(error.errorDescription?.contains("MP4") == true)
        } catch {
            Issue.record("Unexpected error \(error)")
        }
    }

    @Test func errorMessagesAreInSpanish() {
        #expect(TranscriptionError.noAudioTrack.errorDescription?.contains("pista de audio") == true)
        #expect(TranscriptionError.emptyTranscript.errorDescription?.contains("vacía") == true)
        #expect(TranscriptionError.transcriberUnavailable.errorDescription?.contains("disponible") == true)
    }

    @Test func validateRejectsMissingAndNonFileURLs() {
        do {
            _ = try SupportedMedia.validate(URL(fileURLWithPath: "/tmp/no-existe-\(UUID().uuidString).mp4"))
            Issue.record("Expected missing file to fail")
        } catch let error as TranscriptionError {
            #expect(error == .failedToAccessFile)
        } catch {
            Issue.record("Unexpected error \(error)")
        }

        do {
            _ = try SupportedMedia.validate(URL(string: "https://example.com/video.mp4")!)
            Issue.record("Expected remote URL to fail")
        } catch let error as TranscriptionError {
            #expect(error == .failedToAccessFile)
        } catch {
            Issue.record("Unexpected error \(error)")
        }
    }
}
