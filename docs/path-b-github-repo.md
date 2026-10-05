# Path B: a GitHub repository

Source on GitHub, plus a small package `.mk` that tells the builder which commit to build. Use it when you want to share the code, take contributions, keep history, or aim for the MOD Plugin Store.

## Layout

```
Makefile                         top level: plugin + bundle + install
plugins/<name>/                  DSP source (C++, DPF), DistrhoPluginInfo.h, Makefile
bundle/<name>.lv2/               manifest.ttl, <name>.ttl, modgui.ttl, modgui/
mod-plugin-builder/<name>/<name>.mk   the package file
tests/test_<name>.py             the plugin's tests (tools/lv2test.py)
dpf/                             vendored DPF, DSP-only (tools/vendor_dpf.sh)
docs/spec.md, CHANGELOG.md, README.md, LICENSE, ARTWORK-LICENSE.md
```

`templates/plugin/` has all of this except `dpf/` and the docs. **Vendor DPF** (about 2.7 MB) with `tools/vendor_dpf.sh`: the builder fetches a GitHub tarball, which doesn't include submodules. Keep `dpf/utils/symbols`: the link step needs it.

## Identity

The URI is your repo URL (`https://github.com/<owner>/<repo>`), set in `DISTRHO_PLUGIN_URI`, `manifest.ttl`, `<name>.ttl` and `modgui.ttl`. Prefix your bundle and package name with your brand (`nhe-can-abyss`) to avoid clashes with other people's plugins.

## Shipping a build

1. Run the gate (`tools/check.sh`). Also run `make` once for real, to prove the repo's own Makefile builds, and build the package file itself against a copy of the repo: `make -f tools/package_harness.mk PACKAGE=mod-plugin-builder/<name>/<name>.mk SRC=<copy> TGT=<dir> [CROSS=arm32|arm64]`.
2. Commit and push. **The GitHub web uploader takes 100 files at a time** and a repo with vendored DPF has about 200, so use GitHub Desktop (clone, copy the files in, commit, push) or `git`. Hidden files (`.gitignore`) don't come along when you drag a folder in Finder; press Cmd+Shift+. to see them.
3. Get the **full 40-character commit hash**: on GitHub, open *Commits* and use the copy button next to the short hash (the short hash alone won't work), or run `git rev-parse HEAD`. An agent without access to the account can look it up with `git ls-remote https://github.com/<owner>/<repo>` (public repos).
4. Paste it into the package `.mk` as `<P>_VERSION`. You don't need to commit this edit before uploading: the builder reads the `.mk` you upload, then fetches the code at that hash.
5. Upload the package `.mk` at builder.mod.audio and install. The filename must match the prefix (`nhe-can-abyss.mk` ↔ `NHE_CAN_ABYSS_`).

## Continuous checks

`templates/plugin/.github/workflows/check.yml` runs `tools/check.sh` on every push and pull request, so a change from anyone (or anyone's agent) arrives proven. It expects the playbook's `tools/` in the repo; copy the folder in. (The workflow is written but has not yet been run on GitHub; check the first run's log.)

## Store release

MOD publishes community plugins in steps: a builder link for testers, then the beta store, then the official store. Keep a `docs/release.md` checklist: final ports, licence for code and artwork, a manual, presets, tested on each unit type, a demo, and a forum thread. **Freeze ports and the URI before anyone else uses it.** Moving from a single-recipe prototype to a repo usually means a new URI: harvest the presets made on the prototype first and ship them as factory presets (`docs/presets.md`).
