#!/usr/bin/env bash
#
# Fetch the bundled ASR model from the assets-repo GitHub Release.
#
# The model is NOT stored in git (the encoder exceeds GitHub's 100 MB
# per-file limit). It is downloaded here, verified against known SHA256
# checksums, and extracted into assets/ml/asr/ before the app is built.
#
# Idempotent: if the correct files are already present it does nothing.
# Run this before `flutter build` / `flutter run` (locally and in CI).

set -euo pipefail

# --- Pinned release ----------------------------------------------------------
MODEL_NAME="sherpa-onnx-x-asr-960ms-streaming-zipformer-transducer-zh-en-punct-int8-2026-06-05"
RELEASE_TAG="models/x-asr-zh-en-960ms-2026-06-05"
BASE_URL="https://github.com/Aaron-Tsai-iosDeveloper/NamoAmitabha/releases/download/${RELEASE_TAG}"
ARCHIVE_URL="${BASE_URL}/${MODEL_NAME}.tar.gz"

# --- Layout ------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DEST_DIR="${REPO_ROOT}/assets/ml/asr"

# Expected SHA256 of the extracted model files (must match SHA256SUMS.txt
# published alongside the release).
read -r -d '' EXPECTED_SUMS <<'SUMS' || true
017e3cf23097302dbc57ebd72cf4a209cf55c367920669e2d9ce9c0381a96ddd  encoder.int8.onnx
a1cbc9eac2d5e3fb6617a218c67ad6daaa7f4e0fd225f08b2c22ab0413c8c257  decoder.onnx
aedb7fa697b2ab43f20499826fff7c997eea7d67db77be97769aeeeb726e63b3  joiner.int8.onnx
b818a60878b9aae978cbb8ad594acbd403d76d1af2e31ef4197c84e2dbdba27c  tokens.txt
28fc94d67aae53d8c58010fcfb16fc8c2f8dd263e03f3490c98210e354e8f914  bpe.vocab
SUMS

# --- sha256 helper (macOS: shasum, Linux CI: sha256sum) ----------------------
sha256_check() {
  # reads "<hash>  <file>" lines on stdin, verifies against files in $DEST_DIR
  if command -v shasum >/dev/null 2>&1; then
    ( cd "${DEST_DIR}" && shasum -a 256 -c - )
  else
    ( cd "${DEST_DIR}" && sha256sum -c - )
  fi
}

verify() {
  printf '%s\n' "${EXPECTED_SUMS}" | sha256_check >/dev/null 2>&1
}

# --- Skip if already valid ---------------------------------------------------
if [ -d "${DEST_DIR}" ] && verify; then
  echo "ASR model already present and verified. Skipping download."
  exit 0
fi

echo "Fetching ASR model: ${MODEL_NAME}"
mkdir -p "${DEST_DIR}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT
ARCHIVE="${TMP_DIR}/model.tar.gz"

echo "  downloading ${ARCHIVE_URL}"
curl -fL --retry 3 --retry-delay 2 -o "${ARCHIVE}" "${ARCHIVE_URL}"

echo "  extracting"
tar -xzf "${ARCHIVE}" -C "${DEST_DIR}"

echo "  verifying checksums"
if ! printf '%s\n' "${EXPECTED_SUMS}" | sha256_check; then
  echo "ERROR: checksum verification failed after download." >&2
  exit 1
fi

echo "ASR model ready at ${DEST_DIR}"
