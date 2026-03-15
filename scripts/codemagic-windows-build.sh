#!/usr/bin/env bash
set -euo pipefail

# Trigger a Codemagic Windows build via API, poll until completion,
# then download the artifact zip into artifacts/windows/.
#
# Required env vars:
#   CODEMAGIC_API_TOKEN   - API token from Codemagic > Integrations
#   CODEMAGIC_APP_ID      - Application ID from Codemagic dashboard
#   CODEMAGIC_WORKFLOW_ID - Workflow ID (default: windows-release)

API_BASE="https://api.codemagic.io"
POLL_INTERVAL=30
TIMEOUT=1800  # 30 minutes

: "${CODEMAGIC_API_TOKEN:?Missing CODEMAGIC_API_TOKEN}"
: "${CODEMAGIC_APP_ID:?Missing CODEMAGIC_APP_ID}"
: "${CODEMAGIC_WORKFLOW_ID:=windows-release}"

# Extract version from pubspec.yaml
VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
VERSION_NAME="${VERSION%%+*}"
BUILD_NUMBER="${VERSION##*+}"

echo "==> Starting Codemagic build for gecko ${VERSION} (workflow: ${CODEMAGIC_WORKFLOW_ID})"

# 1. Trigger the build
BRANCH="${CI_COMMIT_TAG:-${CI_COMMIT_REF_NAME:-master}}"
RESPONSE=$(curl -sf --retry 3 \
  -H "Content-Type: application/json" \
  -H "x-auth-token: ${CODEMAGIC_API_TOKEN}" \
  -d "{
    \"appId\": \"${CODEMAGIC_APP_ID}\",
    \"workflowId\": \"${CODEMAGIC_WORKFLOW_ID}\",
    \"branch\": \"${BRANCH}\"
  }" \
  "${API_BASE}/builds")

BUILD_ID=$(echo "${RESPONSE}" | jq -r '.buildId')
if [ -z "${BUILD_ID}" ] || [ "${BUILD_ID}" = "null" ]; then
  echo "ERROR: Failed to start build. Response:"
  echo "${RESPONSE}" | jq .
  exit 1
fi

echo "==> Build started: ${BUILD_ID}"
echo "    Dashboard: https://codemagic.io/app/${CODEMAGIC_APP_ID}/build/${BUILD_ID}"

# 2. Poll for completion
ELAPSED=0
while [ "${ELAPSED}" -lt "${TIMEOUT}" ]; do
  sleep "${POLL_INTERVAL}"
  ELAPSED=$((ELAPSED + POLL_INTERVAL))

  STATUS_RESPONSE=$(curl -sf --retry 3 \
    -H "x-auth-token: ${CODEMAGIC_API_TOKEN}" \
    "${API_BASE}/builds/${BUILD_ID}")

  STATUS=$(echo "${STATUS_RESPONSE}" | jq -r '.build.status')
  echo "    [${ELAPSED}s] Build status: ${STATUS}"

  case "${STATUS}" in
    finished)
      echo "==> Build finished successfully"
      break
      ;;
    failed|error|canceled|cancelled)
      echo "ERROR: Build ${STATUS}"
      echo "${STATUS_RESPONSE}" | jq '.build.message // empty'
      exit 1
      ;;
    *)
      # queued, preparing, building, etc. - keep polling
      ;;
  esac
done

if [ "${ELAPSED}" -ge "${TIMEOUT}" ]; then
  echo "ERROR: Build timed out after ${TIMEOUT}s"
  exit 1
fi

# 3. Download all artifacts (Codemagic uses British spelling "artefacts")
mkdir -p artifacts/windows

echo "==> Available artefacts:"
echo "${STATUS_RESPONSE}" | jq -r '.build.artefacts[] | "  - \(.name) (\(.size // "unknown") bytes)"'

# Download each artifact and extract if needed
ARTIFACT_URLS=$(echo "${STATUS_RESPONSE}" | jq -r '.build.artefacts[] | "\(.name)\t\(.url)"')
ARTIFACT_COUNT=0

while IFS=$'\t' read -r NAME URL; do
  [ -z "${URL}" ] && continue

  TMPFILE="/tmp/codemagic_artifact_${ARTIFACT_COUNT}"
  echo "==> Downloading: ${NAME}"
  curl -sfL --retry 3 \
    -H "x-auth-token: ${CODEMAGIC_API_TOKEN}" \
    -o "${TMPFILE}" \
    "${URL}"

  # If it's a zip that contains our setup.exe or portable zip, extract it
  if echo "${NAME}" | grep -qE '\.zip$'; then
    # Check if this zip contains our actual artifacts
    if unzip -l "${TMPFILE}" 2>/dev/null | grep -qE '\.(exe|zip)$'; then
      echo "    Extracting contents..."
      unzip -o -j "${TMPFILE}" -d artifacts/windows/ 2>/dev/null || true
    else
      # It's probably the portable zip itself — check by name
      if echo "${NAME}" | grep -q "windows-x64\.zip"; then
        cp "${TMPFILE}" "artifacts/windows/gecko-${VERSION_NAME}+${BUILD_NUMBER}-windows-x64.zip"
      else
        # Unknown zip — extract to see what's inside
        unzip -o -j "${TMPFILE}" -d artifacts/windows/ 2>/dev/null || \
          cp "${TMPFILE}" "artifacts/windows/${NAME}"
      fi
    fi
  else
    cp "${TMPFILE}" "artifacts/windows/${NAME}"
  fi

  rm -f "${TMPFILE}"
  ARTIFACT_COUNT=$((ARTIFACT_COUNT + 1))
done <<< "${ARTIFACT_URLS}"

# Verify we got the expected files
echo "==> Downloaded artifacts:"
ls -lh artifacts/windows/

SETUP_FILE="artifacts/windows/gecko-${VERSION_NAME}+${BUILD_NUMBER}-windows-x64-setup.exe"
ZIP_FILE="artifacts/windows/gecko-${VERSION_NAME}+${BUILD_NUMBER}-windows-x64.zip"

if [ ! -f "${SETUP_FILE}" ] && [ ! -f "${ZIP_FILE}" ]; then
  echo "ERROR: No expected artifacts found after download"
  exit 1
fi

[ -f "${SETUP_FILE}" ] && echo "==> Installer: ${SETUP_FILE}"
[ -f "${ZIP_FILE}" ] && echo "==> Portable: ${ZIP_FILE}"
echo "==> Windows build complete"
