import SwiftUI

struct ContentView: View {
    @Bindable var model: TranscriptionViewModel

    var body: some View {
        ZStack {
            StudioTheme.ink.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, 28)
                    .padding(.top, 22)
                    .padding(.bottom, 18)

                HStack(alignment: .top, spacing: 24) {
                    DropWellView(model: model)
                        .frame(width: 340)
                    ManuscriptView(model: model)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
        }
        .frame(minWidth: 920, minHeight: 620)
        .task {
            await model.loadLocales()
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers)
        }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Transcribir vídeos")
                    .font(StudioTheme.displayFont)
                    .foregroundStyle(StudioTheme.cream)
                Text("Audio del vídeo, en el dispositivo, a Markdown.")
                    .font(.system(.title3, design: .serif).italic())
                    .foregroundStyle(StudioTheme.muted)
            }
            Spacer()
            Text("Speech · on-device")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(StudioTheme.amber)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .stroke(StudioTheme.amber.opacity(0.4), lineWidth: 1)
                )
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard let url else { return }
            Task { @MainActor in
                model.importFile(url)
            }
        }
        return true
    }
}
