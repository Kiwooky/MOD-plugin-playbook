# Changelog

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
