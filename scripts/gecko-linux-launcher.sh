#!/bin/bash
# Gecko Linux launch wrapper.
#
# Some Linux GPU/driver stacks (older Mesa, certain integrated GPUs, some
# desktop compositors) crash inside Flutter's OpenGL compositor at startup:
# the window opens at its initial size, never receives a GL frame at the real
# size ("Timed out waiting for OpenGL frame ... (have 200x200)") and the
# process dies with a segfault.
#
# This wrapper launches Gecko with the default (GPU-accelerated) renderer and,
# if it crashes (killed by a signal -> exit code >= 128), transparently relaunches
# with Flutter's software renderer (FLUTTER_LINUX_RENDERER=software), which does
# not use OpenGL at all and therefore sidesteps the broken compositor.
#
# Users whose GPU works keep full hardware acceleration; only affected machines
# fall back to software rendering.

set -u
DIR="$(dirname "$(readlink -f "$0")")"
BIN="$DIR/gecko.bin"

# If the renderer was explicitly chosen by the user, honour it and don't interfere.
if [ -n "${FLUTTER_LINUX_RENDERER:-}" ]; then
  exec "$BIN" "$@"
fi

"$BIN" "$@"
code=$?

# Exit codes >= 128 mean the process was killed by a signal (e.g. 139 = SIGSEGV),
# which is the symptom of the OpenGL compositor crash. Retry in software mode.
if [ "$code" -ge 128 ]; then
  echo "Gecko: hardware/OpenGL rendering failed (exit $code) — retrying with the software renderer…" >&2
  FLUTTER_LINUX_RENDERER=software exec "$BIN" "$@"
fi

exit $code
