# Transcribir vídeos

App nativa de macOS que extrae el audio de un vídeo con AVFoundation, lo transcribe en el dispositivo con `SpeechAnalyzer` / `SpeechTranscriber` y guarda el resultado en Markdown.

## Requisitos

- macOS 26 o posterior
- Xcode 26 o posterior
- Primera transcripción en un idioma: el sistema puede descargar el modelo de voz de Apple

## Formatos

**Entrada nativa:** `.mp4`, `.mov`, `.m4v`, `.3gp`  
**Audio:** `.m4a`, `.wav`, `.caf`, `.mp3`, `.aiff`

No se abren contenedores no nativos (`.mkv`, `.webm`, `.avi`, `.wmv`). Para esos, exporta antes a MP4.

## Uso

1. Abre el proyecto con `xcodegen generate` y `open TranscribirVideos.xcodeproj`.
2. Suelta un vídeo o pulsa **Abrir…**.
3. Elige el idioma (por defecto, el del sistema).
4. Cuando termine, **Guardar junto al vídeo** o **Guardar como…**.

El `.md` incluye fuente, fecha, idioma, duración y frases con marcas de tiempo `[mm:ss]`.

La transcripción se hace en el Mac. No se envía audio a un servicio de terceros.

## Desarrollo

```sh
xcodegen generate
./scripts/verify_macos_build.sh
```
