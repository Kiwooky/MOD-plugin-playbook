#!/bin/sh
# SPDX-License-Identifier: MIT
#
# Build a plugin on a Raspberry Pi running Patchbox OS / MODEP, and install
# it into MODEP. Run ON THE PI, from the plugin's folder:
#
#   modep-install                    # make, then install every bin/*.lv2
#   modep-install NAME=my-plugin     # extra make arguments are passed on
#   modep-install path/to/X.lv2 ...  # install bundles that are already built
#
# MODEP loads plugins from /var/modep/lv2 (LV2_PLUGIN_DIR in the
# modep-mod-ui service). A bundle there with the same name is replaced.
# mod-host and mod-ui are restarted at the end so the plugin (and its
# face) show up: reload the browser after that. The current pedalboard
# reloads too, so don't run this mid-song.
#
# Install it on the Pi once, from your Mac (in the playbook folder):
#
#   scp tools/modep_install.sh patch@patchbox.local:~/
#   ssh patch@patchbox.local 'sudo install -m 755 ~/modep_install.sh /usr/local/bin/modep-install'
#
# A plugin built on the Pi is built for the Pi: no cross-compiling, and no
# missing libraries. Builds for the MOD Duo or Dwarf may also run (Duo
# builds on a 32-bit Pi OS, Dwarf builds on a 64-bit one), but a build made
# here is the safe choice.
set -e

LV2_DIR=${MODEP_LV2_DIR:-/var/modep/lv2}

[ -d "$LV2_DIR" ] || { echo "No $LV2_DIR: is this a Patchbox OS / MODEP Pi?"; exit 1; }

# bundles named on the command line (anything ending in .lv2); the rest
# are make arguments
BUNDLES=""
MAKEARGS=""
for a in "$@"; do
    case "$a" in
        *.lv2|*.lv2/) BUNDLES="$BUNDLES ${a%/}" ;;
        *) MAKEARGS="$MAKEARGS $a" ;;
    esac
done

if [ -z "$BUNDLES" ]; then
    [ -f Makefile ] || { echo "No Makefile here: run this in the plugin's folder, or name a .lv2 bundle."; exit 1; }
    echo "Building (make$MAKEARGS) ..."
    # two jobs at a time: a Pi 3 has 1 GB of RAM, and four compilers at once
    # can run it out of memory (or past a weak power supply). MODEP_JOBS=4 to change.
    # shellcheck disable=SC2086
    make -j"${MODEP_JOBS:-2}" $MAKEARGS
    BUNDLES=$(ls -d bin/*.lv2 2>/dev/null || true)
    [ -n "$BUNDLES" ] || { echo "The build made no bin/*.lv2 bundle."; exit 1; }
fi

for b in $BUNDLES; do
    [ -f "$b/manifest.ttl" ] || { echo "$b has no manifest.ttl: not an LV2 bundle?"; exit 1; }
    name=$(basename "$b")
    echo "Installing $name into $LV2_DIR ..."
    sudo rm -rf "$LV2_DIR/$name"
    sudo cp -r "$b" "$LV2_DIR/$name"
    # mod-ui must be able to read the face's files
    sudo chmod -R a+rX "$LV2_DIR/$name"
done

echo "Restarting MODEP (mod-host, mod-ui) ..."
sudo systemctl restart modep-mod-host modep-mod-ui

echo "Done. Reload http://$(hostname).local in your browser."
