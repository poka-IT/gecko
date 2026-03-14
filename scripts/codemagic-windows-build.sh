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

# 3. Extract artifact URLs (Codemagic uses British spelling "artefacts")
mkdir -p artifacts/windows

# Download all Windows artifacts (installer .exe + portable .zip)
ARTIFACT_COUNT=0
for EXT in exe zip; do
  ARTIFACT_URL=$(echo "${STATUS_RESPONSE}" | jq -r "
    .build.artefacts[]
    | select(.name | test(\"\\\\.${EXT}$\"))
    | .url" | head -1)

  if [ -z "${ARTIFACT_URL}" ] || [ "${ARTIFACT_URL}" = "null" ]; then
    echo "WARN: No .${EXT} artifact found"
    continue
  fi

  if [ "${EXT}" = "exe" ]; then
    DEST="artifacts/windows/gecko-${VERSION_NAME}+${BUILD_NUMBER}-windows-x64-setup.exe"
  else
    DEST="artifacts/windows/gecko-${VERSION_NAME}+${BUILD_NUMBER}-windows-x64.zip"
  fi

  echo "==> Downloading: ${DEST}"
  curl -sfL --retry 3 \
    -H "x-auth-token: ${CODEMAGIC_API_TOKEN}" \
    -o "${DEST}" \
    "${ARTIFACT_URL}"

  FILE_SIZE=$(stat -c%s "${DEST}" 2>/dev/null || stat -f%z "${DEST}" 2>/dev/null || echo "unknown")
  echo "    Size: ${FILE_SIZE} bytes"
  ARTIFACT_COUNT=$((ARTIFACT_COUNT + 1))
done

if [ "${ARTIFACT_COUNT}" -eq 0 ]; then
  echo "ERROR: No artifacts found in build output"
  echo "Available artefacts:"
  echo "${STATUS_RESPONSE}" | jq '.build.artefacts[].name'
  exit 1
fi

echo "==> Windows build complete (${ARTIFACT_COUNT} artifacts downloaded)"
