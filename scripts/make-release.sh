#!/usr/bin/env bash
# Sign, notarize, and staple dist/lilshot.app for distribution.
# All secrets/identities come from environment variables — never hardcoded.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_DIR="$ROOT/dist/lilshot.app"
PLIST="$APP_DIR/Contents/Info.plist"
VERSION="${LILSHOT_VERSION:-0.1.0}"
ZIP_PATH="$ROOT/dist/lilshot-v${VERSION}.zip"

missing=()
[[ -z "${LILSHOT_SIGN_IDENTITY:-}" ]] && missing+=(LILSHOT_SIGN_IDENTITY)
[[ -z "${LILSHOT_NOTARY_KEY:-}" ]] && missing+=(LILSHOT_NOTARY_KEY)
[[ -z "${LILSHOT_NOTARY_KEY_ID:-}" ]] && missing+=(LILSHOT_NOTARY_KEY_ID)
[[ -z "${LILSHOT_NOTARY_ISSUER:-}" ]] && missing+=(LILSHOT_NOTARY_ISSUER)

if ((${#missing[@]} > 0)); then
  echo "error: missing required environment variable(s): ${missing[*]}" >&2
  echo "Required: LILSHOT_SIGN_IDENTITY LILSHOT_NOTARY_KEY LILSHOT_NOTARY_KEY_ID LILSHOT_NOTARY_ISSUER" >&2
  echo "Optional: LILSHOT_VERSION (default 0.1.0)" >&2
  exit 1
fi

echo "Assembling app bundle..."
bash "$ROOT/scripts/assemble-app.sh"

echo "Setting CFBundleShortVersionString to ${VERSION}..."
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" "$PLIST"

echo "Codesigning with Developer ID (hardened runtime + timestamp)..."
codesign --force --deep --options runtime --timestamp \
  -s "$LILSHOT_SIGN_IDENTITY" "$APP_DIR"

echo "Verifying codesign..."
codesign --verify --deep --strict "$APP_DIR"

echo "spctl assess (informational pre-notarization; may fail)..."
if spctl --assess --type execute "$APP_DIR"; then
  echo "spctl: accepted (unexpected pre-notarization, continuing)"
else
  echo "spctl: not accepted yet (expected before notarization)"
fi

echo "Creating zip for notarization: ${ZIP_PATH}"
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_DIR" "$ZIP_PATH"

echo "Submitting to notarytool (waiting)..."
submit_out="$(
  xcrun notarytool submit "$ZIP_PATH" \
    --key "$LILSHOT_NOTARY_KEY" \
    --key-id "$LILSHOT_NOTARY_KEY_ID" \
    --issuer "$LILSHOT_NOTARY_ISSUER" \
    --wait 2>&1
)" || {
  echo "$submit_out"
  echo "error: notarytool submit failed" >&2
  exit 1
}
echo "$submit_out"

# Parse status from notarytool --wait output
status="$(echo "$submit_out" | awk '/status:/{print $NF}' | tail -1)"
submission_id="$(echo "$submit_out" | awk '/id:/{print $NF; exit}')"

case "${status}" in
  Accepted)
    echo "Notarization Accepted. Stapling..."
    xcrun stapler staple "$APP_DIR"

    echo "Re-zipping stapled app: ${ZIP_PATH}"
    rm -f "$ZIP_PATH"
    ditto -c -k --keepParent "$APP_DIR" "$ZIP_PATH"

    echo "spctl assess (hard check after staple)..."
    spctl --assess --type execute "$APP_DIR"

    echo "Release artifact: ${ZIP_PATH}"
    ;;
  Invalid)
    echo "error: notarization Invalid" >&2
    if [[ -n "${submission_id}" ]]; then
      xcrun notarytool log "$submission_id" \
        --key "$LILSHOT_NOTARY_KEY" \
        --key-id "$LILSHOT_NOTARY_KEY_ID" \
        --issuer "$LILSHOT_NOTARY_ISSUER" || true
    else
      echo "error: could not parse submission id from notarytool output" >&2
      echo "$submit_out" >&2
    fi
    exit 1
    ;;
  *)
    echo "error: unexpected notarization status: ${status:-<empty>}" >&2
    echo "$submit_out" >&2
    exit 1
    ;;
esac
