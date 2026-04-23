#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

exec flutter run -d chrome \
  --dart-define=USE_FIREBASE_EMULATORS=true \
  --web-port=7357
