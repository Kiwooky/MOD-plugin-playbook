# Path B: a GitHub repository

Source on GitHub, plus a small package `.mk` that tells the builder which commit to build. Use it when you want to share the code, take contributions, keep history, or aim for the MOD Plugin Store.

## Layout

```
Makefile                         top level: plugin + bundle + install
plugins/<name>/                  DSP source (C++, DPF), DistrhoPluginInfo.h, Makefile
bundle/<name>.lv2/               manifest.ttl, <name>.ttl, modgui.ttl, modgui/
mod-plugin-builder/<name>/<name>.mk   the package file
tests/test_<name>.py             the plugin's tests (tools/lv2test.py)
dpf/                             DPF as a git submodule (tools/add_dpf_submodule.sh)
docs/spec.md, CHANGELOG.md, README.md, LICENSE, ARTWORK-LICENSE.md
```

A repo created with GitHub's "Add a license" option starts with that licence in its initial commit (the hall reverb's came with GPL-2 while the code was MIT). Check `LICENSE` matches what the person intends before the first push, and say if you replace it. A plugin built from the template is GPL-3.0-or-later: pick GPL-3.0 in GitHub's menu, or copy the playbook's `LICENSE`.

`templates/plugin/` has all of this except `dpf/` and the docs. **Add DPF as a git submodule** with `tools/add_dpf_submodule.sh` (pinned to the commit the playbook tests against). This is DPF's recommended setup. The package `.mk` fetches it with two lines MOD's own packages use (`<P>_GIT_SUBMODULES = y` and `<P>_PRE_DOWNLOAD_HOOKS += MOD_PLUGIN_BUILDER_DOWNLOAD_WITH_SUBMODULES`, from mod-plugin-builder; Wasted Audio's `wstd-dlay` is one example). Verified on builder.mod.audio (2026-10-08, `tests/submodule-test.mk`).

Repos made with earlier playbook versions have a vendored copy of DPF in `dpf/`. To switch: `git rm -r dpf`, commit, run `tools/add_dpf_submodule.sh`, commit, and update the package `.mk` from the template. Ports and URI don't change.

## Identity

The URI is your repo URL (`https://github.com/<owner>/<repo>`), set in `DISTRHO_PLUGIN_URI`, `manifest.ttl`, `<name>.ttl` and `modgui.ttl`. Prefix your bundle and package name with your brand (`mybrand-echo`) to avoid clashes with other people's plugins.

## Shipping a build

1. Run the gate (`tools/check.sh`). Also run `make` once for real, to prove the repo's own Makefile builds, and build the package file itself against a copy of the repo: `make -f tools/package_harness.mk PACKAGE=mod-plugin-builder/<name>/<name>.mk SRC=<copy> TGT=<dir> [CROSS=arm32|arm64]`.
2. Commit and push with GitHub Desktop or `git`. The web uploader can't add a submodule, and takes 100 files at a time. Hidden files (`.gitignore`) don't come along when you drag a folder in Finder; press Cmd+Shift+. to see them.
3. Get the **full 40-character commit hash**: on GitHub, open *Commits* and use the copy button next to the short hash (the short hash alone won't work), or run `git rev-parse HEAD`. An agent without access to the account can look it up with `git ls-remote https://github.com/<owner>/<repo>` (public repos).
4. Paste it into the package `.mk` as `<P>_VERSION`. You don't need to commit this edit before uploading: the builder reads the `.mk` you upload, then fetches the code at that hash.
5. Upload the package `.mk` at builder.mod.audio and install. The filename must match the prefix (`mybrand-echo.mk` ↔ `MYBRAND_ECHO_`).

## Continuous checks

`templates/plugin/.github/workflows/check.yml` runs `tools/check.sh` on every push and pull request, so a change from anyone (or anyone's agent) arrives proven. It expects the playbook's `tools/` in the repo; copy the folder in. (The workflow is written but has not yet been run on GitHub; check the first run's log.)

## Store release

MOD publishes community plugins in steps: a builder link for testers, then the beta store, then the official store. Keep a `docs/release.md` checklist: final ports, licence for code and artwork, a manual, presets, tested on each unit type, a demo, and a forum thread. **Freeze ports and the URI before anyone else uses it.** Moving from a single-recipe prototype to a repo usually means a new URI: harvest the presets made on the prototype first and ship them as factory presets (`docs/presets.md`).
