#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if command -v xcodegen >/dev/null 2>&1; then
  xcodegen generate
fi

DESTINATION="platform=macOS,arch=arm64"
SCHEME="TranscribirVideos"
PROJECT="TranscribirVideos.xcodeproj"
DERIVED="/tmp/TranscribirVideosBuildVerify"

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO \
  test
