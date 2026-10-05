#!/usr/bin/env bash
# Path B: copy the DSP-only part of DPF (pinned) into ./dpf, so the repo builds
# with no submodules (what MOD's builder and mod-plugin-builder expect).
#   tools/vendor_dpf.sh [target_dir]      default: ./dpf
set -euo pipefail
DPF_SHA=61d38eb638449647fb8395a35c5b8dab7e981ba7
DEST="${1:-dpf}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
git clone -q https://github.com/DISTRHO/DPF.git "$TMP/dpf"
(cd "$TMP/dpf" && git checkout -q "$DPF_SHA")
mkdir -p "$DEST"
cp -r "$TMP/dpf/LICENSE" "$TMP/dpf/Makefile.base.mk" "$TMP/dpf/Makefile.plugins.mk" "$TMP/dpf/distrho" "$DEST/"
mkdir -p "$DEST/utils" && cp -r "$TMP/dpf/utils/symbols" "$DEST/utils/"   # the linker needs utils/symbols
echo "DPF $DPF_SHA vendored into $DEST ($(du -sh "$DEST" | cut -f1))"
