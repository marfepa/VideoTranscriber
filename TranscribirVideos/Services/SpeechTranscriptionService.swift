import AVFoundation
import Foundation
import Speech

enum TranscriptionEvent: Sendable {
    case status(String)
    case progress(Double)
    case partialText(String)
}

actor SpeechTranscriptionService {
    func supportedLocales() async -> [Locale] {
        let locales = await SpeechTranscriber.supportedLocales
        return locales.sorted { lhs, rhs in
            displayName(for: lhs) < displayName(for: rhs)
        }
    }

    func resolvedLocale(matching preferred: Locale) async -> Locale? {
        await SpeechTranscriber.supportedLocale(equivalentTo: preferred)
    }

    func transcribe(
        prepared: PreparedAudio,
        locale: Locale,
        onEvent: @escaping @Sendable (TranscriptionEvent) -> Void
    ) async throws -> [TranscriptSegment] {
        guard SpeechTranscriber.isAvailable else {
            throw TranscriptionError.transcriberUnavailable
        }

        guard let resolved = await SpeechTranscriber.supportedLocale(equivalentTo: locale) else {
            throw TranscriptionError.unsupportedLocale(locale.identifier)
        }

        onEvent(.status("Comprobando el modelo de voz…"))

        var didReserve = false
        do {
            try await AssetInventory.reserve(locale: resolved)
            didReserve = true
        } catch {
            // El inventario puede estar ya reservado; seguimos con la instalación.
        }

        do {
            let segments = try await analyze(
                prepared: prepared,
                locale: resolved,
                onEvent: onEvent
            )
            if didReserve {
                await AssetInventory.release(reservedLocale: resolved)
            }
            return segments
        } catch {
            if didReserve {
                await AssetInventory.release(reservedLocale: resolved)
            }
            throw error
        }
    }

    private func analyze(
        prepared: PreparedAudio,
        locale: Locale,
        onEvent: @escaping @Sendable (TranscriptionEvent) -> Void
    ) async throws -> [TranscriptSegment] {
        let transcriber = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: [.audioTimeRange]
        )

        if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            onEvent(.status("Descargando el modelo de voz de Apple…"))
            try await request.downloadAndInstall()
        }

        try Task.checkCancellation()
        onEvent(.status("Transcribiendo en el dispositivo…"))

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        let audioFile = try AVAudioFile(forReading: prepared.audioURL)
        let duration = prepared.duration > 0 ? prepared.duration : audioDuration(audioFile)

        let resultsTask = Task<[TranscriptSegment], Error> {
            var segments: [TranscriptSegment] = []
            var liveFinalized: [String] = []
            for try await result in transcriber.results {
                try Task.checkCancellation()
                let text = String(result.text.characters)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if result.isFinal {
                    if !text.isEmpty {
                        segments.append(segment(from: result, text: text))
                        liveFinalized.append(text)
                    }
                    let joined = liveFinalized.joined(separator: " ")
                    onEvent(.partialText(joined))
                } else if !text.isEmpty {
                    let preview = (liveFinalized + [text]).joined(separator: " ")
                    onEvent(.partialText(preview))
                }

                let elapsed = result.range.end.seconds
                if duration > 0, elapsed.isFinite {
                    onEvent(.progress(min(0.99, max(0, elapsed / duration))))
                }
            }
            return segments
        }

        do {
            let lastSampleTime = try await analyzer.analyzeSequence(from: audioFile)
            if let lastSampleTime {
                try await analyzer.finalizeAndFinish(through: lastSampleTime)
            } else {
                await analyzer.cancelAndFinishNow()
            }
        } catch is CancellationError {
            await analyzer.cancelAndFinishNow()
            resultsTask.cancel()
            throw TranscriptionError.cancelled
        } catch {
            await analyzer.cancelAndFinishNow()
            resultsTask.cancel()
            throw error
        }

        let segments = try await resultsTask.value
        onEvent(.progress(1))
        return segments
    }

    func displayName(for locale: Locale) -> String {
        locale.localizedString(forIdentifier: locale.identifier)
            ?? Locale.current.localizedString(forIdentifier: locale.identifier)
            ?? locale.identifier
    }

    private func segment(from result: SpeechTranscriber.Result, text: String) -> TranscriptSegment {
        var start = result.range.start.seconds
        for run in result.text.runs {
            if let range = run.audioTimeRange, range.start.seconds.isFinite {
                start = range.start.seconds
                break
            }
        }
        if !start.isFinite || start < 0 {
            start = 0
        }
        return TranscriptSegment(startSeconds: start, text: text)
    }

    private func audioDuration(_ file: AVAudioFile) -> TimeInterval {
        let sampleRate = file.processingFormat.sampleRate
        guard sampleRate > 0 else { return 0 }
        return Double(file.length) / sampleRate
    }
}
