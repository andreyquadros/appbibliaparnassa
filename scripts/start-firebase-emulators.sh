#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FIREBASE_DIR="$ROOT_DIR/firebase"
FUNCTIONS_DIR="$ROOT_DIR/functions"
JAVA_HOME_DEFAULT="/Users/andreyalencarquadros/.local/jdk/jdk-21.0.10+7/Contents/Home"

export JAVA_HOME="${JAVA_HOME:-$JAVA_HOME_DEFAULT}"
export PATH="$JAVA_HOME/bin:$PATH"

if ! command -v java >/dev/null 2>&1; then
  echo "java não encontrado no PATH."
  exit 1
fi

if [ ! -x "$FIREBASE_DIR/node_modules/.bin/firebase" ]; then
  echo "Instalando firebase-tools local..."
  (cd "$FIREBASE_DIR" && npm install)
fi

if [ -f "$FUNCTIONS_DIR/.env.local" ]; then
  # Exporta variaveis (XAI_API_KEY, etc.) para o processo dos emuladores.
  set -a
  # shellcheck source=/dev/null
  . "$FUNCTIONS_DIR/.env.local"
  set +a
fi

cd "$FIREBASE_DIR"
exec ./node_modules/.bin/firebase emulators:start \
  --only firestore,auth,functions,storage,pubsub \
  --config firebase.json \
  --project palavraviva-app-2026
