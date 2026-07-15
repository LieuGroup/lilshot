#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_DIR="$ROOT/dist/lilshot.app"

bash "$ROOT/scripts/assemble-app.sh"

echo "Ad-hoc codesign..."
codesign --force --deep -s - "$APP_DIR"

echo "Done: ${APP_DIR}"
