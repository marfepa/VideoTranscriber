import Foundation
import Testing
@testable import TranscribirVideos

struct MarkdownTranscriptFormatterTests {
    @Test func timestampFormatsMinutesWhenUnderAnHour() {
        #expect(MarkdownTranscriptFormatter.timestamp(0) == "00:00")
        #expect(MarkdownTranscriptFormatter.timestamp(61) == "01:01")
        #expect(MarkdownTranscriptFormatter.timestamp(59.9) == "00:59")
    }

    @Test func timestampIncludesHours() {
        #expect(MarkdownTranscriptFormatter.timestamp(3661) == "01:01:01")
    }

    @Test func timestampClampsInvalidValues() {
        #expect(MarkdownTranscriptFormatter.timestamp(-12) == "00:00")
        #expect(MarkdownTranscriptFormatter.timestamp(.nan) == "00:00")
    }

    @Test func suggestedFileNameReplacesExtension() {
        #expect(MarkdownTranscriptFormatter.suggestedFileName(from: "clase.mp4") == "clase.md")
        #expect(MarkdownTranscriptFormatter.suggestedFileName(from: "notas finales.mov") == "notas finales.md")
    }

    @Test func suggestedFileNameSanitizesForbiddenCharacters() {
        #expect(MarkdownTranscriptFormatter.suggestedFileName(from: "a/b:c.mp4") == "a-b-c.md")
    }

    @Test func formatIncludesMetadataAndTimedLines() {
        let document = TranscriptDocument(
            sourceFileName: "sesion.mp4",
            sourcePath: "/tmp/sesion.mp4",
            localeIdentifier: "es-ES",
            durationSeconds: 125,
            createdAt: Date(timeIntervalSince1970: 1_778_889_600),
            segments: [
                TranscriptSegment(startSeconds: 0, text: "Buenos días."),
                TranscriptSegment(startSeconds: 12.4, text: "Hoy transcribimos el vídeo.")
            ]
        )

        let markdown = MarkdownTranscriptFormatter.format(document)
        #expect(markdown.contains("# Transcripción: sesion"))
        #expect(markdown.contains("- Fuente: `sesion.mp4`"))
        #expect(markdown.contains("- Idioma: es-ES"))
        #expect(markdown.contains("- Duración: 02:05"))
        #expect(markdown.contains("## Transcripción"))
        #expect(markdown.contains("[00:00] Buenos días."))
        #expect(markdown.contains("[00:12] Hoy transcribimos el vídeo."))
    }

    @Test func formatHandlesEmptySpeech() {
        let document = TranscriptDocument(
            sourceFileName: "silencio.m4v",
            sourcePath: "/tmp/silencio.m4v",
            localeIdentifier: "es-ES",
            durationSeconds: 8,
            createdAt: Date(timeIntervalSince1970: 0),
            segments: []
        )
        let markdown = MarkdownTranscriptFormatter.format(document)
        #expect(markdown.contains("_No se detectó habla en el audio._"))
    }
}
