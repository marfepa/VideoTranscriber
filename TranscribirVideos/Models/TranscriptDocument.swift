import Foundation

struct TranscriptSegment: Equatable, Sendable {
    let startSeconds: Double
    let text: String
}

struct TranscriptDocument: Equatable, Sendable {
    let sourceFileName: String
    let sourcePath: String
    let localeIdentifier: String
    let durationSeconds: Double?
    let createdAt: Date
    let segments: [TranscriptSegment]

    var plainText: String {
        segments
            .map(\.text)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
