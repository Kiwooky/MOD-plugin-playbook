# AGENTS.md: building MOD plugins with this playbook

You are helping someone build an audio plugin for MOD devices (Duo, Duo X, Dwarf). This file is your entry point. Read it fully before writing code, then read the docs it points to as you reach each stage.

## 0. Start with the setup interview

Ask these before anything else, one at a time, and record the answers at the top of the plugin's spec (`templates/spec-template.md`). They decide the whole workflow.

1. **How do you want to ship it?**
   - **A. A single `.mk` file for the MOD Online Builder** (recommended for most people). No GitHub needed. You get one file to upload at builder.mod.audio; it installs straight onto a connected MOD. → `docs/path-a-single-recipe.md`
   - **B. A GitHub repository** with a package `.mk` that builds from a commit. Better for sharing source, collaborating, versioning and a later store release. → `docs/path-b-github-repo.md`
   - Not sure? Start with A. The sources live in normal folders either way, so moving to B later is a copy, not a rewrite.
2. **Can you (the agent) run commands?** With a shell (Claude Code, Codex CLI, Cursor, Gemini CLI, or a chat with a code sandbox), run `tools/check.sh` yourself. Without one (chat only), write the files and give the person the exact commands to run, and say clearly which checks were not run.
3. **Which MOD unit(s)?** Duo = 32-bit ARM Cortex-A7, the tightest CPU budget. Duo X and Dwarf = 64-bit ARM. Always build all three.
4. **What is it?** An original effect, or a recreation of specific gear? For recreations, ask for schematics, manuals or recordings, and keep a sources table (what is documented, what is a guess).
5. **The face (pedal GUI):** none yet (`tools/placeholder_face.py` makes one from the TTL, so the first upload has a face), their own artwork, or the stock MOD look?
6. **Name, brand and identity:** plugin name, maker name, and a URI that will never change once shared.

## 1. The loop for every change

1. **Spec first.** Write or update the spec (`templates/spec-template.md`): controls, ranges, defaults, and every mapping marked *guess* or *measured*.
2. **Edit the sources** in `plugins/<name>/` and `bundle/<name>.lv2/`. The TTL is hand-written and must match the code (`docs/lv2-and-mod-rules.md`).
3. **Run the gate:** `tools/check.sh --src plugins/<name> --bundle bundle/<name>.lv2 --test tests/test_<name>.py`. It builds native + Duo + Duo X/Dwarf through the builder's own hooks, compares the TTL with DPF's generator, load-checks, and runs the tests natively and on the Duo build under qemu. **Warnings fail the gate.**
4. **Bump the version** on every upload (`docs/lv2-and-mod-rules.md`, Versioning).
5. **The human uploads** to builder.mod.audio and plays it on the device. Then use `templates/hardware-report.md`.
6. **Every hardware report becomes a failing test first, then the fix** (`docs/hardware-feedback.md`).

## 2. Definition of done (per upload)

- `tools/check.sh` passes: all three builds, no warnings, TTL matches DPF, tests pass natively and under qemu.
- The version is bumped in both the code and the TTL.
- The face ships, even as a placeholder (a face-less first install gets a cached "tuna can" thumbnail).
- CHANGELOG, README and spec say what changed and why, with measured numbers where you have them.
- Anything not verified is said plainly ("not tested on hardware", "CPU estimate only").

## 3. Hard rules (each one cost a real bug, see `docs/lessons.md`)

- **Measure before you claim.** CPU, levels, modulation depth, where feedback runs away: run the benchmark or the test, then state the number. Estimates are labelled as estimates.
- **`run()` is real-time:** no allocation, locks, I/O, printf, or per-sample `pow/exp/sin/tanh`. Allocate in the constructor for 96 kHz.
- **Controls arrive with the first `run()`,** not before `activate()`. Snap smoothers on the first run.
- **Declare `opts:options` and `urid:map` as required features** in the TTL.
- **Put bypass in the plugin** (`lv2:enabled` port, last), with Tails on/off; never click.
- **Soft-knee the outputs.** Anything past 0 dBFS hard-clips at the converter and sounds like digital ticks.
- **Test at guitar level** (peaks around −20 dBFS), with smooth-enveloped test signals.
- **Ports and the URI are frozen once shared.** Never reorder, rename or remove them afterwards.
- **Buttons and footswitches use `mod-widget="switch"`.** Momentary-by-default only when the person asks.
- **Ask about the human's ears.** Tests prove behaviour; only playing it proves it is musical. After each upload, ask what they heard.

## 4. Map of this repo

| Path | What |
| --- | --- |
| `docs/process.md` | The stages from idea to release, for both paths |
| `docs/path-a-single-recipe.md` | Single `.mk` for the Online Builder |
| `docs/path-b-github-repo.md` | GitHub repo + package `.mk` |
| `docs/lv2-and-mod-rules.md` | TTL, ports, bypass, versioning, footswitches |
| `docs/dsp.md` | DSP patterns for MOD's CPUs |
| `docs/testing.md` | The test rig and what to test |
| `docs/modgui.md` | Pedal faces |
| `docs/hardware-feedback.md` | Turning "it sounds wrong" into a fix |
| `docs/lessons.md` | Every rule with the incident behind it |
| `docs/known-mod-issues.md` | MOD-side bugs that look like plugin bugs |
| `templates/plugin/` | A complete, tested template plugin (both paths) |
| `templates/spec-template.md`, `templates/hardware-report.md` | Fill-in templates |
| `tools/` | check.sh, assemble_recipe.py, harness.mk, lv2host.c, lv2test.py, ttlcmp.py, bench.py, placeholder_face.py, render_face.py, knob_filmstrip.py, vendor_dpf.sh |
