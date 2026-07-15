#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_DIR="$ROOT/dist/lilshot.app"

bash "$ROOT/scripts/assemble-app.sh"

# Prefer a stable Developer ID identity: macOS ties Screen Recording (TCC) grants to the
# signing identity, so ad-hoc signing invalidates the permission on every rebuild.
IDENTITY="$(security find-identity -v -p codesigning | grep -m1 -o '"Developer ID Application: [^"]*"' | tr -d '"' || true)"
if [ -n "$IDENTITY" ]; then
  echo "Codesign with: $IDENTITY"
  codesign --force --deep --options runtime --timestamp -s "$IDENTITY" "$APP_DIR"
else
  echo "Ad-hoc codesign (no Developer ID found — TCC grants will reset on each rebuild)..."
  codesign --force --deep -s - "$APP_DIR"
fi

echo "Done: ${APP_DIR}"
