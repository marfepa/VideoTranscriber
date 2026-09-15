import SwiftUI

struct DropWellView: View {
    @Bindable var model: TranscriptionViewModel
    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Mesa de entrada")
                .font(.system(.headline, design: .serif))
                .foregroundStyle(StudioTheme.cream)

            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(StudioTheme.well)
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(
                        isTargeted ? StudioTheme.amber : StudioTheme.amber.opacity(0.28),
                        style: StrokeStyle(lineWidth: isTargeted ? 2 : 1, dash: [7, 6])
                    )

                VStack(spacing: 14) {
                    FilmSprocket()
                        .frame(height: 18)
                        .padding(.horizontal, 28)

                    Image(systemName: model.sourceFileName == nil ? "film.stack" : "waveform")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(StudioTheme.amber)
                        .symbolRenderingMode(.hierarchical)

                    if let name = model.sourceFileName {
                        VStack(spacing: 6) {
                            Text(name)
                                .font(.system(.title3, design: .serif))
                                .foregroundStyle(StudioTheme.cream)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                            if model.durationSeconds > 0 {
                                Text(MarkdownTranscriptFormatter.timestamp(model.durationSeconds))
                                    .font(StudioTheme.mono)
                                    .foregroundStyle(StudioTheme.muted)
                            }
                        }
                    } else {
                        VStack(spacing: 8) {
                            Text("Suelta un vídeo aquí")
                                .font(.system(.title3, design: .serif))
                                .foregroundStyle(StudioTheme.cream)
                            Text("MP4, MOV, M4V · el audio se transcribe en el dispositivo")
                                .font(.callout)
                                .foregroundStyle(StudioTheme.muted)
                                .multilineTextAlignment(.center)
                        }
                    }

                    HStack(spacing: 10) {
                        Button("Abrir…") {
                            model.openPanel()
                        }
                        .buttonStyle(StudioButtonStyle(prominent: true))
                        .disabled(model.isBusy)

                        if model.isBusy {
                            Button("Cancelar") {
                                model.cancel()
                            }
                            .buttonStyle(StudioButtonStyle(prominent: false))
                        }
                    }
                    .padding(.top, 4)

                    FilmSprocket()
                        .frame(height: 18)
                        .padding(.horizontal, 28)
                }
                .padding(28)
            }
            .dropDestination(for: URL.self) { urls, _ in
                guard let url = urls.first else { return false }
                model.importFile(url)
                return true
            } isTargeted: { targeted in
                isTargeted = targeted
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Idioma")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(StudioTheme.muted)
                Picker("Idioma", selection: $model.selectedLocaleIdentifier) {
                    ForEach(model.locales, id: \.identifier) { locale in
                        Text(model.localeNames[locale.identifier] ?? locale.identifier)
                            .tag(locale.identifier)
                    }
                }
                .labelsHidden()
                .disabled(model.isBusy)
                .tint(StudioTheme.amber)
            }

            Text("No se envía nada a la nube. Si el modelo de voz no está instalado, macOS lo descarga de Apple una sola vez.")
                .font(.caption)
                .foregroundStyle(StudioTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct FilmSprocket: View {
    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<11, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(StudioTheme.amber.opacity(0.35))
                    .frame(width: 8, height: 11)
                Spacer(minLength: 0)
            }
        }
    }
}

struct StudioButtonStyle: ButtonStyle {
    var prominent: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .serif).weight(.medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(prominent ? StudioTheme.amber : StudioTheme.amberSoft)
            )
            .foregroundStyle(prominent ? StudioTheme.ink : StudioTheme.cream)
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}
