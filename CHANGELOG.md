# Changelog

## 0.4.1 — 2026-10-07

- **The no-shell face recipe now lives in `AGENTS.md` itself** (`modgui.ttl` example, the download line, the file table per style, colours), with a link to the working `tests/face-fetch-test.mk`. A second free-account run built a fuzz and told the person "a single `.mk` can't carry the face", either from a stale `AGENTS.md` or because `docs/modgui.md` didn't fetch. One fetch now carries everything.
- Links stamped `?v=0.4.1`.

## 0.4.0 — 2026-10-07

One link to start: point any AI at `AGENTS.md` and it has everything it needs.

- **Licence: GPL-3.0-or-later** (was MIT), template plugin included. The cookbook-derived parts keep MOD's MIT notice (`LICENSES/`).
- `AGENTS.md` "Start here": reading the repo by raw URL when there's no clone; the MOD plugin cookbook's prompt and `gain.mk` as required reading; a table of where the playbook overrides the cookbook; pointers into the template plugin for agents that can't run the tools.
- The setup interview is now a kick-off: the idea first; the agent's tools, the path (A by default) and the build targets worked out without asking; then the shape proposed in one message, cookbook style. Follows the cookbook's own finding that an up-front "which workflow?" question made it worse.
- README "Start with one link"; `process.md` and the spec template follow the kick-off.
- New `tools/stock_face.py`: the MOD SDK's stock pedals (japanese, boxy, british, lata) picked from the ports, a style and a colour. Knob count picks the panel; extra footswitches (`--stomp`) widen a boxy box; the first enumeration becomes a dropdown. Pre-renders the template, ships only the art it uses (256 colours), renders with MOD's fonts. The kick-off now offers a face ("what should it look like?").
- `face_click_test.py` drives mod-ui's dropdown (`custom-select`); `render_face.py` loads `@import`ed fonts and mod-ui's page fonts (`PB_FONTS_DIR`).
- **Cache-busting links.** A second free-account run read the *old* `AGENTS.md` after 0.4.0 was pushed: AI fetch services cache GitHub pages, and the plain link kept serving the cached file while `?v=0.4.0` served the new one. The README one-liner and every playbook link in `AGENTS.md` now carry `?v=<version>`; `tools/bump_links.py` stamps them and rebuilds `ALL-IN-ONE.md` before each push (`docs/harvesting.md`). Also a root `.gitignore` (`.DS_Store`, `__pycache__`).
- **From a first free-account run** (a drive pedal built in a chat with no shell): the kick-off settles the maker before building; a build against a self-made DPF stand-in is reported as "parses only", with the first upload as the compile test; default loudness is checked against bypass as average level within ±3 dB, not peaks.
- **Stock faces without a shell:** the recipe downloads the MOD SDK template, CSS and art at build time (`stock_face.py --fetch-at-build`, `FETCH.txt` → `wget` steps in `assemble_recipe.py`, or written by hand from the table in `modgui.md`). A stock face then costs a few lines, so chats without a shell can ship one. Verified: `tests/face-fetch-test.mk` built on builder.mod.audio and its white japanese face rendered on a Duo's pedalboard.
- **Works in chats that can't fetch GitHub.** `AGENTS.md` links every file as a full `github.com/.../blob/...` URL (GitHub blocks bots from `/tree/` and `/raw/`, and some chat apps refuse `raw.githubusercontent.com` and URLs the AI builds itself), and tells the AI to stop after one failed retry and ask for `ALL-IN-ONE.md`: one generated file (`tools/make_all_in_one.py`) with the guide, the cookbook prompt, the key docs and the template. Found testing from a free Claude account.
- **Rules by effect type.** New `docs/effect-profile.md`: where the idea starts (imagined, a reference sound, specific gear) and the traits that decide which rules, tests and template parts apply. Bypass: a click-free crossfade for every plugin, Tails only for effects with a tail. Output limiting: only for effects that can run away (wet path); none for gain and drive, since only the converter clips. Oversampling now covers drives, not just loops; testing at the source's real level; versioning reframed as an automatic cache-buster on path A. The template's parts and tests are tagged by trait to strip down; its limiter now acts on the wet only.
- Docs and tools no longer name specific plugins; incidents are described by type (a hall reverb, a BBD echo, an early digital delay, an oil-can delay).
- Verified in tests: every stock style renders; a boxy selector and an extra footswitch pass the click test with mod-ui's code; the template's own face still passes. Not yet seen on a unit.
- Not yet verified: a novice run from the link alone, in a chat without a shell.

## 0.3.1 — 2026-10-06

Harvested from a hall reverb session (cookbook prototype → its own repo). Only the plugin-related learnings; the session's MOD UI troubleshooting is already in `known-mod-issues.md`.

- `lv2test.py`: `rt60()` (Schroeder T30) and `onset_ms()` for reverb and pre-delay tests.
- Docs: setting reverb loop gain from a target RT60 and scaling tank lengths from the reference rate; time knobs that read true through upstream delays; rounding versus truncation in lo-fi loops (`dsp.md`); reverb and first-run tests (`testing.md`); preset labels versus folder names, shipping the original's setting as a preset (`presets.md`); GitHub's generated licence (`path-b-github-repo.md`); reading `version`/`stability` from `/effect/get` (`known-mod-issues.md`). Six lessons with their incidents.
- Verified: `rt60()` and `onset_ms()` reproduce the hall reverb's suite (RT60 5.63 / 5.58 / 5.72 s, onset 81.9 ms).

## 0.3.0 — 2026-10-06

Harvested from a bucket-brigade (BBD) echo session (cookbook prototype → its own repo, built without this playbook).

- `face_click_test.py`: follows mod-ui's script semantics (one persistent `event.data`; no `change` back for the script's own `set_port_value`; values clamped and unchanged sets skipped, as in `setPortValue`); presses from each control's default; touch taps for toggles; finds script-driven controls by the attribute naming their port and presses them with mouse, wobble and touch.
- Docs: script-driven controls and radio banks with "hold to add", measuring a printed knob sweep, fitting positions to a mockup, aligning output jacks with printed legends, renaming labels but never symbols (`modgui.md`); landing smoothers, noise floors in loops, resistor mixing networks, noise as modulation (`dsp.md`); ARM vs x86 in clock-phase code, the rdflib `index` trap, reading what mod-ui hands a face (`testing.md`); `scp -O` on macOS (`presets.md`). Sixteen lessons with their incidents.
- Verified: the new `face_click_test.py` passes the BBD echo 1.0.0, the digital delay and the template; fails exactly the three switches that failed on a Duo when the BBD echo's 1.0.1 face is put back; fails three switches when the face script's switch handler is emptied.
- Not yet verified on a unit: the BBD echo's script-driven switches (1.0.2 onward), the output jack alignment.

## 0.2.0 — 2026-10-06

Harvested from an early digital delay session (cookbook prototype → its own repo).

- New tools: `face_click_test.py` (clicks every control with mod-ui's own widget code, with and without a 2 px wobble; runs the face script), `presets_from_device.py` (presets made on a unit → factory presets, read back and checked), `package_harness.mk` (builds a path-B package `.mk` against a local repo copy).
- New doc: `presets.md`.
- Lessons and topic docs: click zones for multi-position switches, `funcs.set_port_value`, swapping strip art with a class, the documentation button, dry at unity in bypass whatever Mix says, original-style bypass for recreations, clocked (BBD/early digital) delays, compander modelling, opposite-polarity outputs in mono, delay measurement by cross-correlation, the 100-file web upload limit, `git ls-remote` for the commit hash, URI changes orphaning presets, front panels over blurry schematics.
- Verified: `face_click_test.py` passes the digital delay's face and the template, and fails three controls when the digital delay's film widgets come back; `presets_from_device.py` reproduces the digital delay's ten factory presets exactly from the Duo's files and is re-runnable; `package_harness.mk` builds the digital delay and the template natively and for arm64.
- Not yet verified on a unit: the strip-swap face script, the documentation button.

## 0.1.0 — 2026-10-05

First version, from a hall reverb handover and an oil-can delay build.

- `AGENTS.md` with the setup interview (single `.mk` or GitHub repo), the loop, definition of done and hard rules; `CLAUDE.md` points to it.
- Template plugin (`simple-echo`) that builds both ways; its 13 tests pass natively and on the Duo build under qemu.
- Tools: `check.sh` (the gate), `placeholder_face.py`, `assemble_recipe.py`, `harness.mk`, `lv2host.c`, `lv2test.py`, `ttlcmp.py`, `bench.py`, `render_face.py`, `knob_filmstrip.py`, `vendor_dpf.sh`.
- Docs: process, both paths, LV2/MOD rules, DSP, testing, faces, hardware feedback, lessons, known MOD issues, harvesting.
- Verified: both paths build for native, Duo and Duo X/Dwarf; the gate fails on a TTL mismatch and on a compiler warning; the tick detector finds planted clicks and ignores clean input; the face renderer reproduces a hand-tuned render; every bundle file (TTLs, face HTML/CSS, images) round-trips through the assembled `.mk` byte for byte.
- Not yet verified: the template uploaded to builder.mod.audio and played on a device (including the placeholder face in mod-ui); the GitHub Actions workflow.
