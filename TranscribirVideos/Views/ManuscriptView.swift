import SwiftUI

struct ManuscriptView: View {
    @Bindable var model: TranscriptionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Manuscrito")
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(StudioTheme.cream)
                Spacer()
                if model.phase == .transcribing {
                    Text("escuchando…")
                        .font(.system(.caption, design: .serif).italic())
                        .foregroundStyle(StudioTheme.amber)
                }
            }

            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(StudioTheme.paper)
                    .shadow(color: .black.opacity(0.28), radius: 18, y: 8)

                VStack(spacing: 0) {
                    Rectangle()
                        .fill(StudioTheme.paperEdge)
                        .frame(height: 10)

                    ScrollView {
                        Group {
                            if model.markdown.isEmpty && model.liveText.isEmpty {
                                emptyState
                            } else if model.markdown.isEmpty {
                                Text(model.liveText)
                                    .font(StudioTheme.bodySerif)
                                    .foregroundStyle(StudioTheme.inkText.opacity(0.82))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                            } else {
                                Text(model.markdown)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(StudioTheme.inkText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                            }
                        }
                        .padding(28)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }

            progressStrip

            HStack(spacing: 10) {
                Button("Guardar junto al vídeo") {
                    model.saveAlongside()
                }
                .buttonStyle(StudioButtonStyle(prominent: true))
                .disabled(!model.canSave)

                Button("Guardar como…") {
                    model.saveAs()
                }
                .buttonStyle(StudioButtonStyle(prominent: false))
                .disabled(!model.canSave)

                Button("Copiar") {
                    model.copyMarkdown()
                }
                .buttonStyle(StudioButtonStyle(prominent: false))
                .disabled(model.markdown.isEmpty)

                Spacer()
            }

            if let saved = model.savedURL {
                Text("Archivo: \(saved.path)")
                    .font(.caption)
                    .foregroundStyle(StudioTheme.muted)
                    .lineLimit(2)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("La transcripción aparecerá aquí.")
                .font(.system(.title3, design: .serif))
                .foregroundStyle(StudioTheme.inkText)
            Text("Cada frase se guarda con su marca de tiempo, lista para un .md.")
                .font(.system(.body, design: .serif))
                .foregroundStyle(StudioTheme.inkText.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 24)
    }

    private var progressStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(StudioTheme.amberSoft)
                    Capsule()
                        .fill(StudioTheme.amber)
                        .frame(width: max(8, proxy.size.width * model.progress))
                }
            }
            .frame(height: 6)

            HStack {
                Text(model.statusMessage)
                    .font(.callout)
                    .foregroundStyle(StudioTheme.cream)
                Spacer()
                if model.isBusy {
                    Text("\(Int((model.progress * 100).rounded()))%")
                        .font(StudioTheme.mono)
                        .foregroundStyle(StudioTheme.muted)
                }
            }

            if let error = model.errorMessage {
                Text(error)
                    .font(.callout)
                    .foregroundStyle(Color(red: 0.93, green: 0.62, blue: 0.42))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
