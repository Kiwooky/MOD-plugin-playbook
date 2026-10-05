# Changelog

## 0.3.1 — 2026-10-06

Harvested from the Taj Mahal session (Alesis-preset hall reverb: cookbook prototype → its own repo). Only the plugin-related learnings; the session's MOD UI troubleshooting is already in `known-mod-issues.md`.

- `lv2test.py`: `rt60()` (Schroeder T30) and `onset_ms()` for reverb and pre-delay tests.
- Docs: setting reverb loop gain from a target RT60 and scaling tank lengths from the reference rate; time knobs that read true through upstream delays; rounding versus truncation in lo-fi loops (`dsp.md`); reverb and first-run tests (`testing.md`); preset labels versus folder names, shipping the original's setting as a preset (`presets.md`); GitHub's generated licence (`path-b-github-repo.md`); reading `version`/`stability` from `/effect/get` (`known-mod-issues.md`). Six lessons with their incidents.
- Verified: `rt60()` and `onset_ms()` reproduce Taj Mahal's suite (RT60 5.63 / 5.58 / 5.72 s, onset 81.9 ms).

## 0.3.0 — 2026-10-06

Harvested from the EC-280 session (Dynacord EC 280 bucket-brigade echo: cookbook prototype → its own repo, built without this playbook).

- `face_click_test.py`: follows mod-ui's script semantics (one persistent `event.data`; no `change` back for the script's own `set_port_value`; values clamped and unchanged sets skipped, as in `setPortValue`); presses from each control's default; touch taps for toggles; finds script-driven controls by the attribute naming their port and presses them with mouse, wobble and touch.
- Docs: script-driven controls and radio banks with "hold to add", measuring a printed knob sweep, fitting positions to a mockup, aligning output jacks with printed legends, renaming labels but never symbols (`modgui.md`); landing smoothers, noise floors in loops, resistor mixing networks, noise as modulation (`dsp.md`); ARM vs x86 in clock-phase code, the rdflib `index` trap, reading what mod-ui hands a face (`testing.md`); `scp -O` on macOS (`presets.md`). Sixteen lessons with their incidents.
- Verified: the new `face_click_test.py` passes EC-280 1.0.0, MultiPlay and the template; fails exactly the three switches that failed on a Duo when EC-280's 1.0.1 face is put back; fails three switches when the face script's switch handler is emptied.
- Not yet verified on a unit: EC-280's script-driven switches (1.0.2 onward), the output jack alignment.

## 0.2.0 — 2026-10-06

Harvested from the MultiPlay 20/20 session (cookbook prototype → its own repo).

- New tools: `face_click_test.py` (clicks every control with mod-ui's own widget code, with and without a 2 px wobble; runs the face script), `presets_from_device.py` (presets made on a unit → factory presets, read back and checked), `package_harness.mk` (builds a path-B package `.mk` against a local repo copy).
- New doc: `presets.md`.
- Lessons and topic docs: click zones for multi-position switches, `funcs.set_port_value`, swapping strip art with a class, the documentation button, dry at unity in bypass whatever Mix says, original-style bypass for recreations, clocked (BBD/early digital) delays, compander modelling, opposite-polarity outputs in mono, delay measurement by cross-correlation, the 100-file web upload limit, `git ls-remote` for the commit hash, URI changes orphaning presets, front panels over blurry schematics.
- Verified: `face_click_test.py` passes MultiPlay's face and the template, and fails three controls when MultiPlay's film widgets come back; `presets_from_device.py` reproduces MultiPlay's ten factory presets exactly from the Duo's files and is re-runnable; `package_harness.mk` builds MultiPlay and the template natively and for arm64.
- Not yet verified on a unit: the strip-swap face script, the documentation button.

## 0.1.0 — 2026-10-05

First version, from the Taj Mahal handover and the Can-Abyss Delay build.

- `AGENTS.md` with the setup interview (single `.mk` or GitHub repo), the loop, definition of done and hard rules; `CLAUDE.md` points to it.
- Template plugin (`simple-echo`) that builds both ways; its 13 tests pass natively and on the Duo build under qemu.
- Tools: `check.sh` (the gate), `placeholder_face.py`, `assemble_recipe.py`, `harness.mk`, `lv2host.c`, `lv2test.py`, `ttlcmp.py`, `bench.py`, `render_face.py`, `knob_filmstrip.py`, `vendor_dpf.sh`.
- Docs: process, both paths, LV2/MOD rules, DSP, testing, faces, hardware feedback, lessons, known MOD issues, harvesting.
- Verified: both paths build for native, Duo and Duo X/Dwarf; the gate fails on a TTL mismatch and on a compiler warning; the tick detector finds planted clicks and ignores clean input; the face renderer reproduces a hand-tuned render; every bundle file (TTLs, face HTML/CSS, images) round-trips through the assembled `.mk` byte for byte.
- Not yet verified: the template uploaded to builder.mod.audio and played on a device (including the placeholder face in mod-ui); the GitHub Actions workflow.
