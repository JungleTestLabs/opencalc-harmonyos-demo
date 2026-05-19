#!/usr/bin/env bash
# Fix DevEco Studio 6.0.2 hvigor "SDK component missing" on macOS.
#
# Root cause: the 6.0.2 SDK installer drops components into
# /Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/<comp>/
# instead of the flat layout sdk/default/<comp>/ that hvigor scans by default.
# This script creates top-level symlinks so hvigor's flat scan finds them:
#   ets, js, native, previewer, toolchains -> openharmony/<same>
#
# Do NOT touch the root sdk-pkg.json — DevEco's launch-time SDK integrity check
# requires it. Removing it causes DevEco to refuse to start.
#
# Idempotent. Run after every DevEco Studio install/upgrade.
# Requires macOS App Management permission for Terminal (Sequoia+).
#
# Usage:
#   sudo bash scripts/fix-deveco-sdk.sh          # apply fix
#   sudo bash scripts/fix-deveco-sdk.sh --undo   # remove symlinks

set -e

SDK_ROOT="/Applications/DevEco-Studio.app/Contents/sdk/default"
PKG_ROOT="$SDK_ROOT/sdk-pkg.json"
PKG_ROOT_OFF="$PKG_ROOT.disabled-by-fix"
COMPONENTS=(ets js native previewer toolchains)

case "${1:-apply}" in
  --undo|undo)
    echo "==> Removing symlinks"
    for c in "${COMPONENTS[@]}"; do
      if [ -L "$SDK_ROOT/$c" ]; then
        rm "$SDK_ROOT/$c"
        echo "    removed symlink $SDK_ROOT/$c"
      fi
    done
    # Also restore root sdk-pkg.json if a prior version of this script disabled it.
    if [ -f "$PKG_ROOT_OFF" ] && [ ! -f "$PKG_ROOT" ]; then
      mv "$PKG_ROOT_OFF" "$PKG_ROOT"
      echo "    restored $PKG_ROOT (was disabled by older fix)"
    fi
    exit 0
    ;;
esac

if [ ! -d "$SDK_ROOT/openharmony" ]; then
  echo "ERROR: $SDK_ROOT/openharmony not found. Install HarmonyOS 6.0.2 SDK first."
  exit 1
fi

# If a previous run disabled root sdk-pkg.json, restore it — DevEco needs it.
if [ -f "$PKG_ROOT_OFF" ] && [ ! -f "$PKG_ROOT" ]; then
  mv "$PKG_ROOT_OFF" "$PKG_ROOT"
  echo "    restored $PKG_ROOT (was disabled by older fix)"
fi

for c in "${COMPONENTS[@]}"; do
  if [ ! -d "$SDK_ROOT/openharmony/$c" ]; then
    echo "    skip $c (openharmony/$c not present)"
    continue
  fi
  if [ -L "$SDK_ROOT/$c" ] || [ -e "$SDK_ROOT/$c" ]; then
    echo "    skip $c (already exists)"
    continue
  fi
  ln -s "openharmony/$c" "$SDK_ROOT/$c"
  echo "    linked $SDK_ROOT/$c -> openharmony/$c"
done

echo ""
echo "Done. Now Sync in DevEco."
