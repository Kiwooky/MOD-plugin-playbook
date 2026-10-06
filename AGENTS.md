# AGENTS.md: building MOD plugins with this playbook

You are helping someone build an audio plugin for MOD devices (Duo, Duo X, Dwarf). This file is your entry point. Someone may have sent you nothing but its link: that is enough. Follow it from the top.

## Start here

### Reading this repo

Every path in this file is relative to the repo root.

- **You have a shell:** clone `https://github.com/Kiwooky/MOD-plugin-playbook` and work inside it.
- **You can only fetch URLs:** read any file at `https://raw.githubusercontent.com/Kiwooky/MOD-plugin-playbook/main/<path>`, e.g. `.../main/docs/dsp.md`. Fetch the raw URL, not the `github.com/.../blob/...` page.
- **You can't fetch at all:** ask the person to paste the file you need, one at a time.

### Required reading, before your first reply

1. **The MOD plugin cookbook's prompt:** <https://raw.githubusercontent.com/mod-audio/mod-plugin-cookbook/main/prompts/plugin-from-idea.md>. MOD's own guide to the single-`.mk` recipe format and the Online Builder. This playbook builds on it; read it as the foundation.
2. **Its worked example:** <https://raw.githubusercontent.com/mod-audio/mod-plugin-cookbook/main/examples/gain.mk>. For anything with a delay line or LFO, also `examples/ce2-chorus.mk` in the same repo.
3. **The rest of this file.** Read the `docs/` it points to as you reach each stage, not all up front.

### Where the playbook overrides the cookbook

The cookbook is right about the recipe's shape. These are the gaps it leaves, each found on real hardware (`docs/lessons.md`). Where the two disagree, follow the playbook.

| Cookbook | Playbook |
| --- | --- |
| Pre-flight: ControlPort count = `kParameterCount` − 1 | **Equal** to `kParameterCount` |
| Examples omit required features | Declare `opts:options` and `urid:map` (`docs/lv2-and-mod-rules.md`) |
| No bypass port; MOD hard-bypasses (an instant switch that can click) | In-plugin bypass (`lv2:enabled`, last port) with a short crossfade, dry at unity. A Tails option only for effects with a tail |
| No output safety | Feedback effects: a soft limit on the wet path. Gain and drive: none, the clipping is the sound (`docs/effect-profile.md`) |
| `export` + `printf` for everything | Over ~100 KB, `export` fails; use `$(file)` (`docs/path-a-single-recipe.md`) |
| No versioning | Bump the build number on every upload, automatically: MOD caches a plugin's face and ports by version, so a re-upload with the same number shows the old one. Path B adds real releases |
| No pedal face; say it's unsupported | Faces are supported; ship one from the first upload (`docs/modgui.md`) |
| Generate, then hand over | Test before handing over; then ask what they heard |

Without a shell you can't run the playbook's tools, so write the `.mk` by hand in the cookbook's shape with these overrides applied. Copy the patterns from the template plugin (`templates/plugin/plugins/simple-echo/SimpleEchoPlugin.cpp` and `templates/plugin/bundle/simple-echo.lv2/simple-echo.ttl`): each part is tagged with the trait it serves (`[every]`, `[tail]`, `[feedback]`, `[buffer]`, `[mix]`); keep what your effect needs (`docs/effect-profile.md`).

## 0. The kick-off

The person may be new to all of this. Lead with their idea, not with plumbing. (MOD learned this with the cookbook: an extra "which workflow?" question up front made it worse for everyone. Don't ask what you can work out or default.)

**Your first reply:** one line on what you'll do together (describe a sound → get a file to upload at builder.mod.audio → play it on the MOD), then ask what they'd like to build. If they've already described it, skip straight to the proposal.

**Work these out yourself. Don't ask:**

- **Can you run commands?** You know. With a shell (Claude Code, Codex CLI, Cursor, Gemini CLI, a chat with a code sandbox), clone the repo and run `tools/check.sh` yourself. Without one, write the files, give the exact commands, and say clearly which checks were not run.
- **How it ships:** **path A**, a single `.mk` for the Online Builder (`docs/path-a-single-recipe.md`). No GitHub needed. Bring up **path B**, a GitHub repo (`docs/path-b-github-repo.md`), only if they mention GitHub, sharing source, collaborators or the MOD store, or once the plugin works on their unit. Moving later is a copy, not a rewrite.
- **Build targets:** always all three (Duo, Duo X, Dwarf).

**Work out where the idea starts** (`docs/effect-profile.md`). Usually it's clear from their first message; ask only if it isn't:

- **Imagined**, with no prior art: get the feel in their words and what it's near; build it from known blocks.
- **A reference sound** ("Eddie Van Halen's phaser"): research the gear and how it works, and confirm it with them before building.
- **Specific gear**, often with schematics: ask for schematics, panel photos, the manual and recordings, and keep a sources table.

Then tick the effect's **traits** (tail, feedback loop, buffer, nonlinear/gain, level-sensitive, modulated delay, stereo, Mix knob). They decide which rules, tests and template parts apply. For level-sensitive effects, ask what plugs in: guitar and bass are around −20 dBFS, synths and line sources much hotter.

**Then propose the shape in one message** (the cookbook's style) and end with *"Confirm or adjust, then I'll build it."*:

1. **Name and maker:** a name from their description. Offer their own name or alias as the maker, so their work carries their name.
2. **Category, mono/stereo, the knobs:** each knob with range, default and unit. Bypass, plus a Tails option if the effect has a tail.
3. **Which MOD they'll play it on.** The Duo (32-bit ARM Cortex-A7) has the tightest CPU budget; say if the design is heavy.
4. **The face:** offer to dress the pedal so it doesn't arrive as MOD's default "tuna can". One question: *what should it look like?*
   - **Compact stompbox** with the big rocker footswitch (Boss-like): `japanese`, up to 8 knobs.
   - **Hammond-style box** (DIY builds, MXR-like): `boxy`, 1–8 knobs, a selector, or up to 12 sliders. It widens for more controls.
   - **Metal British box:** `british`, up to 4 knobs. **Tin can:** `lata`, up to 8 knobs.
   - **Their own artwork:** a custom face (`docs/modgui.md`), after the sound works.

   Plus a colour. You work out the size: the knob count picks the panel, and every extra footswitch they'd stomp (Tails, Hold, Tap) widens the box. Check what fits with `tools/stock_face.py <bundle> --style <s> --dry-run` before proposing. Without a shell the stock art can't be packed into the recipe: say it ships with MOD's default look for now, and that a face later is just a version bump.
5. **What you'll base it on:** for a reference sound, what your research found and the gear you'll model; for specific gear, what they can send. Keep a sources table (documented vs guessed).

The URI follows from the name (`urn:mod-cookbook:<name>` on path A) and never changes once shared. The licence is GPL-3.0-or-later, inherited from the template; say so if they ask, and change it only if they bring their own code. Record the answers at the top of the spec (`templates/spec-template.md`); without files, keep the spec as a short block in the chat.

If the request is already specific ("a CE-2 chorus"), state your choices in two lines and build. Keep questions to the ones that change the plugin.

## 1. The loop for every change

1. **Spec first.** Write or update the spec (`templates/spec-template.md`): controls, ranges, defaults, and every mapping marked *guess* or *measured*.
2. **Edit the sources** in `plugins/<name>/` and `bundle/<name>.lv2/`. The TTL is hand-written and must match the code (`docs/lv2-and-mod-rules.md`).
3. **Run the gate:** `tools/check.sh --src plugins/<name> --bundle bundle/<name>.lv2 --test tests/test_<name>.py`. It builds native + Duo + Duo X/Dwarf through the builder's own hooks, compares the TTL with DPF's generator, load-checks, and runs the tests natively and on the Duo build under qemu. **Warnings fail the gate.**
4. **Bump the build number** on every upload, without asking (`docs/lv2-and-mod-rules.md`, Versioning).
5. **The human uploads** to builder.mod.audio and plays it on the device. Then use `templates/hardware-report.md`.
6. **Every hardware report becomes a failing test first, then the fix** (`docs/hardware-feedback.md`).

## 2. Definition of done (per upload)

- `tools/check.sh` passes: all three builds, no warnings, TTL matches DPF, tests pass natively and under qemu.
- The version is bumped in both the code and the TTL.
- The face ships, stock or placeholder at least (a face-less first install gets a cached "tuna can" thumbnail).
- CHANGELOG, README and spec say what changed and why, with measured numbers where you have them.
- Anything not verified is said plainly ("not tested on hardware", "CPU estimate only").

## 3. Hard rules (each one cost a real bug, see `docs/lessons.md`)

- **Measure before you claim.** CPU, levels, modulation depth, where feedback runs away: run the benchmark or the test, then state the number. Estimates are labelled as estimates.
- **`run()` is real-time:** no allocation, locks, I/O, printf, or per-sample `pow/exp/sin/tanh`. Buffers are allocated in the constructor, sized for 96 kHz.
- **Controls arrive with the first `run()`,** not before `activate()`. Snap smoothers on the first run.
- **Declare `opts:options` and `urid:map` as required features** in the TTL.
- **Apply rules by trait, not by habit** (`docs/effect-profile.md`). Most rules here were learned on delays and reverbs; a fuzz doesn't need Tails or an output limiter.
- **Put bypass in the plugin** (`lv2:enabled` port, last) with a ~10 ms crossfade, so switching never clicks. A Tails option only if the effect has a tail.
- **Only the converter clips.** Audio between plugins is floating point, so going over 0 dBFS inside a chain is fine; past 0 dBFS at the last output it hard-clips as "digital ticks". Effects that can run away (feedback) get a soft limit on the wet path. Gain and drive pedals don't: a boost is meant to be loud, and the Level knob manages it.
- **Test at the source's real level** (guitar peaks around −20 dBFS; synths and line sources are hotter), with smooth-enveloped test signals.
- **Ports and the URI are frozen once shared.** Never reorder, rename or remove them afterwards.
- **Buttons and footswitches use `mod-widget="switch"`.** Momentary-by-default only when the person asks. Run `tools/face_click_test.py` on every face change, and before blaming the device for a control that doesn't respond.
- **If it has a Mix knob, bypass leaves the dry at unity whatever Mix says.**
- **Ask about the human's ears.** Tests prove behaviour; only playing it proves it is musical. After each upload, ask what they heard.

## 4. Map of this repo

| Path | What |
| --- | --- |
| `docs/process.md` | The stages from idea to release, for both paths |
| `docs/effect-profile.md` | Where the idea starts (imagined, reference, specific gear) and the traits that decide rules, tests and template parts |
| `docs/path-a-single-recipe.md` | Single `.mk` for the Online Builder |
| `docs/path-b-github-repo.md` | GitHub repo + package `.mk` |
| `docs/lv2-and-mod-rules.md` | TTL, ports, bypass, versioning, footswitches |
| `docs/dsp.md` | DSP patterns for MOD's CPUs |
| `docs/testing.md` | The test rig and what to test |
| `docs/modgui.md` | Pedal faces |
| `docs/hardware-feedback.md` | Turning "it sounds wrong" into a fix |
| `docs/lessons.md` | Every rule with the incident behind it |
| `docs/known-mod-issues.md` | MOD-side bugs that look like plugin bugs |
| `docs/presets.md` | Factory presets, and carrying over presets made on a unit |
| `templates/plugin/` | A complete, tested template plugin (both paths) |
| `templates/spec-template.md`, `templates/hardware-report.md` | Fill-in templates |
| `tools/` | check.sh, assemble_recipe.py, harness.mk, package_harness.mk, lv2host.c, lv2test.py, ttlcmp.py, bench.py, placeholder_face.py, stock_face.py, render_face.py, face_click_test.py, presets_from_device.py, knob_filmstrip.py, vendor_dpf.sh |
