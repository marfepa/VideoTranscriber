import Foundation

enum MarkdownTranscriptFormatter {
    static func format(_ document: TranscriptDocument) -> String {
        var lines: [String] = []
        let title = document.sourceFileName.deletingPathExtension
        lines.append("# Transcripción: \(title)")
        lines.append("")
        let sourceName = document.sourceFileName.replacingOccurrences(of: "`", with: "'")
        lines.append("- Fuente: `\(sourceName)`")
        lines.append("- Fecha: \(dateString(document.createdAt))")
        lines.append("- Idioma: \(document.localeIdentifier)")
        if let duration = document.durationSeconds, duration.isFinite, duration > 0 {
            lines.append("- Duración: \(timestamp(duration))")
        }
        lines.append("")
        lines.append("## Transcripción")
        lines.append("")

        if document.segments.isEmpty {
            lines.append("_No se detectó habla en el audio._")
        } else {
            for segment in document.segments {
                let text = segment.text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { continue }
                lines.append("[\(timestamp(segment.startSeconds))] \(text)")
                lines.append("")
            }
            if lines.last == "" {
                lines.removeLast()
            }
        }

        lines.append("")
        return lines.joined(separator: "\n")
    }

    static func suggestedFileName(from sourceFileName: String) -> String {
        let base = sourceFileName.deletingPathExtension
        let sanitized = sanitize(base)
        let name = sanitized.isEmpty ? "transcripcion" : sanitized
        return "\(name).md"
    }

    static func timestamp(_ seconds: Double) -> String {
        let total = max(0, seconds.isFinite ? Int(seconds.rounded(.down)) : 0)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }

    static func sanitize(_ raw: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\:?%*|\"<>")
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let mapped = trimmed.unicodeScalars.map { invalid.contains($0) ? "-" : Character($0) }
        let joined = String(mapped)
        let collapsed = joined.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

private extension String {
    var deletingPathExtension: String {
        (self as NSString).deletingPathExtension
    }
}
