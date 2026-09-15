import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class TranscriptionViewModel {
    enum Phase: Equatable {
        case idle
        case preparing
        case transcribing
        case completed
        case failed
    }

    var phase: Phase = .idle
    var sourceURL: URL?
    var sourceFileName: String?
    var locales: [Locale] = []
    var selectedLocaleIdentifier: String = Locale.current.identifier
    var statusMessage: String = "Suelta un vídeo para transcribirlo en este Mac."
    var liveText: String = ""
    var markdown: String = ""
    var progress: Double = 0
    var errorMessage: String?
    var savedURL: URL?
    var durationSeconds: Double = 0
    var localeNames: [String: String] = [:]

    var canSave: Bool { !markdown.isEmpty && phase == .completed }
    var isBusy: Bool { phase == .preparing || phase == .transcribing }

    var selectedLocale: Locale {
        Locale(identifier: selectedLocaleIdentifier)
    }

    private let service = SpeechTranscriptionService()
    private var job: Task<Void, Never>?
    private var jobGeneration = 0

    init() {
        MediaAudioExtractor.sweepTemporaryFiles()
    }

    func loadLocales() async {
        let list = await service.supportedLocales()
        locales = list
        var names: [String: String] = [:]
        for locale in list {
            names[locale.identifier] = await service.displayName(for: locale)
        }
        localeNames = names

        if let resolved = await service.resolvedLocale(matching: .current) {
            selectedLocaleIdentifier = resolved.identifier
        } else if let spanish = list.first(where: { $0.identifier.hasPrefix("es") }) {
            selectedLocaleIdentifier = spanish.identifier
        } else if let first = list.first {
            selectedLocaleIdentifier = first.identifier
        }
    }

    func openPanel() {
        guard let url = TranscriptFileStore.openPanel() else { return }
        importFile(url)
    }

    func importFile(_ url: URL) {
        do {
            _ = try SupportedMedia.validate(url)
        } catch {
            phase = .failed
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            statusMessage = "No se puede transcribir este archivo."
            return
        }

        startTranscription(of: url)
    }

    func cancel() {
        guard isBusy else { return }
        job?.cancel()
        statusMessage = "Cancelando…"
    }

    func saveAlongside() {
        guard canSave, let sourceURL, let sourceFileName else { return }
        let fileName = MarkdownTranscriptFormatter.suggestedFileName(from: sourceFileName)
        do {
            let url = try TranscriptFileStore.saveAlongsideSource(
                markdown: markdown,
                sourceURL: sourceURL,
                fileName: fileName
            )
            savedURL = url
            statusMessage = "Guardado en \(url.lastPathComponent)."
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func saveAs() {
        guard canSave, let sourceFileName else { return }
        let suggested = MarkdownTranscriptFormatter.suggestedFileName(from: sourceFileName)
        do {
            if let url = try TranscriptFileStore.saveWithPanel(
                markdown: markdown,
                suggestedFileName: suggested
            ) {
                savedURL = url
                statusMessage = "Guardado en \(url.lastPathComponent)."
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func copyMarkdown() {
        guard !markdown.isEmpty else { return }
        TranscriptFileStore.copyToPasteboard(markdown)
        statusMessage = "Markdown copiado al portapapeles."
    }

    private func startTranscription(of url: URL) {
        job?.cancel()
        jobGeneration += 1
        let generation = jobGeneration
        let locale = selectedLocale

        sourceURL = url
        sourceFileName = url.lastPathComponent
        markdown = ""
        liveText = ""
        savedURL = nil
        errorMessage = nil
        progress = 0
        durationSeconds = 0
        phase = .preparing
        statusMessage = "Preparando el audio…"

        job = Task { [weak self] in
            guard let self else { return }
            var prepared: PreparedAudio?
            defer {
                if let prepared {
                    MediaAudioExtractor.cleanup(prepared)
                }
            }

            do {
                let local = try await MediaAudioExtractor.prepare(url: url)
                prepared = local
                guard !Task.isCancelled, self.jobGeneration == generation else { return }

                self.durationSeconds = local.duration
                self.phase = .transcribing

                let segments = try await self.service.transcribe(
                    prepared: local,
                    locale: locale,
                    onEvent: { event in
                        Task { @MainActor [self] in
                            guard self.jobGeneration == generation else { return }
                            self.handle(event)
                        }
                    }
                )

                guard !Task.isCancelled, self.jobGeneration == generation else { return }
                let document = TranscriptDocument(
                    sourceFileName: local.sourceFileName,
                    sourcePath: local.sourcePath,
                    localeIdentifier: locale.identifier,
                    durationSeconds: local.duration,
                    createdAt: Date(),
                    segments: segments
                )
                if segments.isEmpty {
                    throw TranscriptionError.emptyTranscript
                }
                self.markdown = MarkdownTranscriptFormatter.format(document)
                self.liveText = document.plainText
                self.progress = 1
                self.phase = .completed
                self.statusMessage = "Transcripción lista para guardar en Markdown."
            } catch is CancellationError {
                guard self.jobGeneration == generation else { return }
                self.phase = .idle
                self.statusMessage = "Transcripción cancelada."
                self.progress = 0
            } catch let error as TranscriptionError where error == .cancelled {
                guard self.jobGeneration == generation else { return }
                self.phase = .idle
                self.statusMessage = error.localizedDescription
                self.progress = 0
            } catch {
                guard self.jobGeneration == generation else { return }
                self.phase = .failed
                self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                self.statusMessage = "No se pudo transcribir el archivo."
            }
        }
    }

    private func handle(_ event: TranscriptionEvent) {
        switch event {
        case .status(let message):
            statusMessage = message
        case .progress(let value):
            progress = value
        case .partialText(let text):
            liveText = text
        }
    }
}
