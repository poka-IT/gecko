#!/bin/bash
# Launch duniter-mocks in sealing mode, run the migration integration test, then clean up.
#
# Usage: ./test/integration/run.sh
#
# Prerequisites:
#   - duniter-mocks repo at ../duniter-mocks (sibling directory)
#   - Flutter SDK in PATH

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DUNITER_MOCKS_DIR="$PROJECT_DIR/../duniter-mocks"

if [ ! -d "$DUNITER_MOCKS_DIR" ]; then
  echo "ERROR: duniter-mocks not found at $DUNITER_MOCKS_DIR"
  exit 1
fi

cleanup() {
  echo "==> Cleaning up duniter-mocks..."
  cd "$DUNITER_MOCKS_DIR"
  ./run.sh stop 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Always restart fresh to guarantee clean chain state
echo "==> Restarting duniter-mocks in sealing mode (clean state)..."
cd "$DUNITER_MOCKS_DIR"
./run.sh restart --sealing || { echo "ERROR: failed to start duniter-mocks"; exit 1; }

echo "==> Waiting for duniter-mocks to be ready..."
./run.sh wait-ready || { echo "ERROR: duniter-mocks not ready"; exit 1; }

echo "==> Ensuring ObjectBox native library is available..."
cd "$PROJECT_DIR"
if [ ! -f lib/libobjectbox.dylib ]; then
  bash <(curl -s https://raw.githubusercontent.com/objectbox/objectbox-dart/main/install.sh) || { echo "ERROR: failed to install ObjectBox library"; exit 1; }
fi

echo "==> Running migration integration test..."
flutter test test/integration/migrate_identity_test.dart --timeout 120s
