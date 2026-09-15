import SwiftUI

@main
struct TranscribirVideosApp: App {
    @State private var model = TranscriptionViewModel()

    var body: some Scene {
        Window("Transcribir vídeos", id: "main") {
            ContentView(model: model)
        }
        .defaultSize(width: 1080, height: 720)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Abrir vídeo…") {
                    model.openPanel()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(after: .saveItem) {
                Button("Guardar Markdown…") {
                    model.saveAs()
                }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(!model.canSave)

                Button("Guardar junto al vídeo") {
                    model.saveAlongside()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(!model.canSave)

                Button("Copiar Markdown") {
                    model.copyMarkdown()
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(model.markdown.isEmpty)
            }
        }
    }
}
