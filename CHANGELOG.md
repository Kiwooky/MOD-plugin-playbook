# Changelog

## 0.1.0 — 2026-10-05

First version, from the Taj Mahal handover and the Can-Abyss Delay build.

- `AGENTS.md` with the setup interview (single `.mk` or GitHub repo), the loop, definition of done and hard rules; `CLAUDE.md` points to it.
- Template plugin (`simple-echo`) that builds both ways; its 13 tests pass natively and on the Duo build under qemu.
- Tools: `check.sh` (the gate), `placeholder_face.py`, `assemble_recipe.py`, `harness.mk`, `lv2host.c`, `lv2test.py`, `ttlcmp.py`, `bench.py`, `render_face.py`, `knob_filmstrip.py`, `vendor_dpf.sh`.
- Docs: process, both paths, LV2/MOD rules, DSP, testing, faces, hardware feedback, lessons, known MOD issues, harvesting.
- Verified: both paths build for native, Duo and Duo X/Dwarf; the gate fails on a TTL mismatch and on a compiler warning; the tick detector finds planted clicks and ignores clean input; the face renderer reproduces a hand-tuned render; every bundle file (TTLs, face HTML/CSS, images) round-trips through the assembled `.mk` byte for byte.
- Not yet verified: the template uploaded to builder.mod.audio and played on a device (including the placeholder face in mod-ui); the GitHub Actions workflow.
