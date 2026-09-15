import Foundation

enum TranscriptionError: LocalizedError, Equatable {
    case transcriberUnavailable
    case unsupportedLocale(String)
    case unsupportedContainer(String)
    case noAudioTrack
    case failedToAccessFile
    case failedToPrepareAudio
    case emptyTranscript
    case cancelled
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .transcriberUnavailable:
            return "La transcripción nativa de Apple no está disponible en este Mac."
        case .unsupportedLocale(let identifier):
            return "El idioma «\(identifier)» no tiene modelo de voz descargable en este dispositivo."
        case .unsupportedContainer(let ext):
            return "El formato .\(ext) no es nativo de AVFoundation. Usa MP4, MOV o M4V (o extrae el audio a M4A/WAV)."
        case .noAudioTrack:
            return "Este archivo no tiene pista de audio para transcribir."
        case .failedToAccessFile:
            return "No se pudo acceder al archivo. Ábrelo de nuevo desde la app."
        case .failedToPrepareAudio:
            return "No se pudo leer el audio. Prueba a exportarlo como MP4 con AAC o como M4A."
        case .emptyTranscript:
            return "La transcripción terminó vacía. Comprueba que el vídeo tenga voz clara."
        case .cancelled:
            return "Transcripción cancelada."
        case .saveFailed(let message):
            return "No se pudo guardar el Markdown: \(message)"
        }
    }
}
