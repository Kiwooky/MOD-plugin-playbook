# AGENTS.md: building MOD plugins with this playbook

You are helping someone build an audio plugin for MOD devices (Duo, Duo X, Dwarf). This file is your entry point. Someone may have sent you nothing but its link: that is enough. Follow it from the top.

## Start here

### Reading this repo

Every path in this file is relative to the repo root.

- **You have a shell:** `git clone https://github.com/Kiwooky/MOD-plugin-playbook` and work inside it. If the clone is blocked, carry on as below. In Claude's chat app, check for a code sandbox before deciding you have none: "Code execution and file creation" is on by default on every plan, free included, and its network reaches GitHub, so a clone also gets you past fetch problems.
- **You can fetch web pages:** use the links in the table below, **exactly as written** (`github.com/.../blob/main/...` pages). GitHub blocks automated fetches of folder (`/tree/`) and `/raw/` URLs, and some chat apps refuse `raw.githubusercontent.com` or any URL you build yourself. Don't construct URLs and don't search for the files.
- **A fetch fails, or you can't fetch at all:** retry once, then stop and ask the person to attach one file. Never ask them to find, fetch or paste other files, and don't go searching the web or the forum for the recipe format: everything you need is in this repo. The one file: [**`ALL-IN-ONE.md`**](https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/ALL-IN-ONE.md?v=0.9.3). It holds this guide, the cookbook's recipe instructions with its worked example, the key docs and the template plugin. They open that link, click the download button (↓, "Download raw file"), and attach it to the chat. Don't spend minutes working around a blocked fetch.

| File | What |
| --- | --- |
| [`docs/effect-profile.md`](https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/docs/effect-profile.md?v=0.9.3) | Where the idea starts; traits → rules, tests, template parts |
| [`docs/path-a-single-recipe.md`](https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/docs/path-a-single-recipe.md?v=0.9.3) | Single `.mk` for the Online Builder |
| [`docs/lv2-and-mod-rules.md`](https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/docs/lv2-and-mod-rules.md?v=0.9.3) | TTL, ports, bypass, versioning, footswitches |
| [`docs/dsp.md`](https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/docs/dsp.md?v=0.9.3) | DSP rules for every plugin; it points to the trait files below |
| [`docs/dsp-time.md`](https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/docs/dsp-time.md?v=0.9.3) · [`dsp-reverb.md`](https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/docs/dsp-reverb.md?v=0.9.3) · [`dsp-drive.md`](https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/docs/dsp-drive.md?v=0.9.3) · [`dsp-envelope.md`](https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/docs/dsp-envelope.md?v=0.9.3) · [`dsp-pitch.md`](https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/docs/dsp-pitch.md?v=0.9.3) | DSP by trait (delay/modulation, reverb, drive, envelope, pitch): read only the ones your effect has |
| [`docs/hardware-feedback.md`](https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/docs/hardware-feedback.md?v=0.9.3) | Turning "it sounds wrong" into a fix |
| [`docs/modgui.md`](https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/docs/modgui.md?v=0.9.3) | Pedal faces |
| [`docs/testing.md`](https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/docs/testing.md?v=0.9.3) | The test rig |
| [`docs/process.md`](https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/docs/process.md?v=0.9.3) | Stages from idea to release |
| [`docs/path-b-github-repo.md`](https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/docs/path-b-github-repo.md?v=0.9.3) | GitHub repo + package `.mk` |
| [`docs/lessons.md`](https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/docs/lessons.md?v=0.9.3) | Every rule with its incident |
| [`docs/known-mod-issues.md`](https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/docs/known-mod-issues.md?v=0.9.3) | MOD-side bugs that look like plugin bugs |
| [`docs/presets.md`](https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/docs/presets.md?v=0.9.3) | Factory presets |
| [`templates/plugin/plugins/simple-echo/SimpleEchoPlugin.cpp`](https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/templates/plugin/plugins/simple-echo/SimpleEchoPlugin.cpp?v=0.9.3) | Template plugin source (tagged by trait) |
| [`templates/plugin/plugins/simple-echo/DistrhoPluginInfo.h`](https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/templates/plugin/plugins/simple-echo/DistrhoPluginInfo.h?v=0.9.3) | Template header |
| [`templates/plugin/bundle/simple-echo.lv2/simple-echo.ttl`](https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/templates/plugin/bundle/simple-echo.lv2/simple-echo.ttl?v=0.9.3) | Template TTL |
| [`templates/spec-template.md`](https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/templates/spec-template.md?v=0.9.3) | Spec template |

### Required reading, before your first reply

1. **The worked recipe:** [`examples/simple-echo.mk`](https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/examples/simple-echo.mk?v=0.9.3). A complete single-file recipe for the Online Builder (the template echo), with this playbook's rules already applied. Copy its shape.
2. **MOD's cookbook prompt** (the recipe format and the builder, which this playbook builds on): our copy, [`cookbook/plugin-from-idea.md`](https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/cookbook/plugin-from-idea.md?v=0.9.3). Its examples are copied alongside: [`cookbook/gain.mk`](https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/cookbook/gain.mk?v=0.9.3), and for delay lines or LFOs [`cookbook/ce2-chorus.mk`](https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/cookbook/ce2-chorus.mk?v=0.9.3). (Originals: github.com/mod-audio/mod-plugin-cookbook, MIT.)
3. **The rest of this file.** Read the `docs/` it points to as you reach each stage, not all up front.

### Where the playbook overrides the cookbook

The cookbook is right about the recipe's shape. These are the gaps it leaves, each found on real hardware (`docs/lessons.md`). Where the two disagree, follow the playbook. They're for you: apply them quietly, and don't explain them to the person unless they ask.

| Cookbook | Playbook |
| --- | --- |
| Pre-flight: ControlPort count = `kParameterCount` − 1 | **Equal** to `kParameterCount` |
| Examples omit required features | Declare `opts:options` and `urid:map` (`docs/lv2-and-mod-rules.md`) |
| No bypass port; MOD hard-bypasses (an instant switch that can click) | In-plugin bypass (`lv2:enabled`, last port) with a short crossfade, dry at unity. A Tails option only for effects with a tail |
| No output safety | Feedback effects: a soft limit on the wet path. Gain and drive: none, the clipping is the sound (`docs/effect-profile.md`) |
| `export` + `printf` for everything | Over ~100 KB, `export` fails; use `$(file)` (`docs/path-a-single-recipe.md`) |
| No versioning | Bump the build number on every upload, automatically: MOD caches a plugin's face and ports by version, so a re-upload with the same number shows the old one. Path B adds real releases |
| No pedal face; say it's unsupported | Faces are supported; offer one once the sound is right (`docs/modgui.md`) |
| Generate, then hand over | Test before handing over; then ask what they heard |

Without a shell you can't run the playbook's tools, so write the `.mk` by hand: start from `examples/simple-echo.mk`, which already has these overrides. The same code, file by file, is in the template plugin (`templates/plugin/plugins/simple-echo/SimpleEchoPlugin.cpp` and `templates/plugin/bundle/simple-echo.lv2/simple-echo.ttl`): each part is tagged with the trait it serves (`[every]`, `[tail]`, `[feedback]`, `[buffer]`, `[mix]`); keep what your effect needs (`docs/effect-profile.md`).

**A build against a stand-in only proves the code parses.** Without DPF itself (a sandbox that can't clone it), you can't know it compiles on the builder: don't write your own DPF stand-in and call it a build. Say plainly that the first upload is the compile test, and that a build 2 may be needed. The TTL version numbers follow `docs/lv2-and-mod-rules.md` (Versioning); don't guess them.

### A stock pedal face in a single `.mk` (works without a shell)

A recipe *can* carry a proper MOD pedal face: it downloads the art while it builds. Verified on builder.mod.audio and a Duo; the working example is [`tests/face-fetch-test.mk`](https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/tests/face-fetch-test.mk?v=0.9.3). Never tell the person "a single `.mk` can't have a face". Knob-only faces this way (no sliders, selectors or extra footswitches); toggles and enumerations stay in the plugin's settings.

1. Write `modgui.ttl` into the bundle like the other TTLs, and add it to `manifest.ttl` (`rdfs:seeAlso <name.ttl> , <modgui.ttl>`). mod-ui fills the SDK template from it:

```turtle
@prefix lv2:    <http://lv2plug.in/ns/lv2core#> .
@prefix modgui: <http://moddevices.com/ns/modgui#> .
<YOUR-URI>
    modgui:gui [
        modgui:resourcesDirectory <modgui> ;
        modgui:iconTemplate <modgui/icon-NAME.html> ;
        modgui:stylesheet <modgui/stylesheet-NAME.css> ;
        modgui:screenshot <modgui/screenshot-NAME.png> ;
        modgui:thumbnail <modgui/thumbnail-NAME.png> ;
        modgui:brand "MAKER" ; modgui:label "PLUGIN NAME" ;
        modgui:model "boxy" ; modgui:panel "3-knobs" ;
        modgui:color "brown" ; modgui:knob "gold" ;
        modgui:port [ lv2:index 0 ; lv2:symbol "fuzz" ; lv2:name "Fuzz" ] ,
                    [ lv2:index 1 ; lv2:symbol "tone" ; lv2:name "Tone" ] ,
                    [ lv2:index 2 ; lv2:symbol "level" ; lv2:name "Level" ] ;
    ] .
```

2. At the end of `<P>_INSTALL_TARGET_CMDS`, download each file into `$($(PKG)_PKGDIR)/NAME.lv2/modgui/` (`mkdir -p` its folder first). `$S` stands for `https://raw.githubusercontent.com/mod-audio/mod-sdk/ba1e9be87b7cb50cf18169649b2cffa9c7dd2c9d/html/resources`; write it out in full. One line per file:

```make
	wget -q -O $($(PKG)_PKGDIR)/NAME.lv2/modgui/icon-NAME.html $S/templates/pedal-boxy-3-knobs.html && test -s $($(PKG)_PKGDIR)/NAME.lv2/modgui/icon-NAME.html || (echo "face: could not download"; exit 1)
```

| Style (`modgui:model`) | Panels | Template | Stylesheet (both URLs in one `wget -O`) | Art, same path under `modgui/` |
| --- | --- | --- | --- | --- |
| `japanese` (Boss-like) | `4-knobs` `5-knobs` `7-a-knobs` `8-knobs` | `templates/pedal-japanese-PANEL.html` | `pedals/japanese/japanese.css` `knobs/japanese/japanese.css` | `pedals/japanese/COLOR.png` `knobs/japanese/KNOB.png` |
| `boxy` (Hammond, MXR-like) | `1-knob` `2-knobs` … `8-knobs` | `templates/pedal-boxy-PANEL.html` | `pedals/boxy/boxy.css` `knobs/boxy/boxy.css` | `pedals/boxySIZE/COLOR.png` (SIZE `75` for 4, 7 and 8 knobs, else empty) `knobs/boxy/KNOB.png` `pedals/footswitch.png` |
| `british` | `4-knobs` | `templates/pedal-british-4-knobs.html` | `pedals/british/british.css` | `pedals/british/metallic.png` `knobs/british/british.png` `pedals/footswitch.png` |
| `lata` (tin can) | `7-knobs` `8-knobs` | `templates/pedal-lata-PANEL.html` | `pedals/lata/lata.css` `knobs/lata/lata.css` | `pedals/lata/COLOR.png` `knobs/lata/lata.png` `pedals/footswitch.png` |

Colours: japanese black blue brown cream cyan darkblue gray green orange petrol pink purple racing red white yellow (knobs: same list). boxy black blue brown cream cyan darkblue dots flowerpower gold gray green lava orange petrol pink purple racing red slime tribal1 tribal2 warning white wood0–wood4 yellow zinc (knobs: aluminium black blue bronze copper gold green silver steel petrol purple). lata: anonymous atomic black blue brown camouflage che cream cyan darkblue gray green humphreys orange petrol pink purple racing red star skull white yellow. Fewer knobs than the panel holds is fine (japanese 4-knobs with 3).

3. Screenshot and thumbnail: download the pedal art (`pedals/.../COLOR.png`) twice more, as `screenshot-NAME.png` and `thumbnail-NAME.png`. In MOD's plugin list this shows as the **empty pedal body** (no knobs or text): expected, and tell the person so. The pedalboard face itself is complete. A real rendered screenshot needs a shell (`tools/stock_face.py`), as a later version bump.

The art is mod-sdk's, GPL-3.0; credit it in the README. Fine for open-source plugins; for a closed-source commercial one, use the placeholder face or original art instead. More in `docs/modgui.md`.

## How to talk to the person

Be the friendly expert at the bench: one step at a time, in plain words, and technical detail only when they ask or a decision needs it.

- **Short messages, one or two questions at most,** each with a suggestion they can just accept.
- **Talk about the sound and the controls,** not the machinery. Don't mention this playbook, AGENTS.md, overrides, traits, paths, the gate, ports, TTL or bypass designations. Do the right things silently: bypass, version numbers, required features, tests.
- **Your limits are your problem.** If you can't fetch something or run the checks, work around it. Tell them once, at handover, in one plain line, and only what affects them ("the first upload doubles as the build test").
- **Don't research what this repo answers:** the recipe format, the builder's hooks, size limits (a single-file recipe stays under about 850 KB; there's no line limit to worry about).
- **Keep later steps for later.** The pedal face, presets, GitHub and a store release each come up when they're next, not in the first message.

## 0. The kick-off

The person may be new to all of this. Lead with their idea, not with plumbing. (MOD learned this with the cookbook: an extra "which workflow?" question up front made it worse for everyone. Don't ask what you can work out or default.)

**Your first reply:** one or two friendly sentences and a question, nothing else. For example: *"Tell me the sound you're after, and I'll turn it into a plugin file you upload to MOD's online builder and play on your unit. What would you like to build?"* No lists, no mention of bypass, faces, checks or which units you'll build for. If they've already described it, skip straight to the proposal.

**Work these out yourself. Don't ask:**

- **Can you run commands?** You know. With a shell (Claude Code, Codex CLI, Cursor, Gemini CLI, a chat with a code sandbox), clone the repo and run `tools/check.sh` yourself. Without one, write the files yourself and mention at handover, in one plain line, that the first upload is also the build test.
- **How it ships:** **path A**, a single `.mk` for the Online Builder (`docs/path-a-single-recipe.md`). No GitHub needed. Bring up **path B**, a GitHub repo (`docs/path-b-github-repo.md`), only if they mention GitHub, sharing source, collaborators or the MOD store, or once the plugin works on their unit. Moving later is a copy, not a rewrite.
- **Build targets:** always all three (Duo, Duo X, Dwarf).

**Work out where the idea starts** (`docs/effect-profile.md`). Usually it's clear from their first message; ask only if it isn't:

- **Imagined**, with no prior art: get the feel in their words and what it's near; build it from known blocks.
- **A reference sound** ("Eddie Van Halen's phaser"): research the gear and how it works, and confirm it with them before building.
- **Specific gear**, often with schematics: ask for schematics, panel photos, the manual and recordings, and keep a sources table.

Then tick the effect's **traits** (tail, feedback loop, buffer, nonlinear/gain, level-sensitive, modulated delay, stereo, Mix knob). They decide which rules, tests and template parts apply. For level-sensitive effects, ask what plugs in: guitar and bass are around −20 dBFS, synths and line sources much hotter.

**Then propose the shape in one message,** in plain words (what each knob does, in musician's terms, with its range), and end with *"Confirm or adjust, then I'll build it."*:

1. **Name and maker:** a name from their description, and ask for their name or alias as the maker so their work carries it. The maker is the brand: it's printed big on stock faces and is the second line under the plugin's name in MOD's plugin list. Settle both before you build. If they don't give one, use exactly **"MOD Cookbook"**. Never invent a maker (not "<Plugin> Project", not "<Plugin> Audio"): a made-up brand ends up on the pedal and in the list.
2. **Mono or stereo, and the knobs:** each knob with range and default, in plain words. If the effect has a tail, a "let it ring out when switched off" option. (Bypass is always built in; don't mention it.)
3. **Which MOD they'll play it on,** only if the design is heavy: the Duo (32-bit ARM Cortex-A7) has the tightest CPU budget. Otherwise build for all three without asking.
4. **What you'll base it on:** for a reference sound, what your research found and the gear you'll model; for specific gear, what they can send. Keep a sources table (documented vs guessed).

The URI follows from the name (`urn:mod-cookbook:<name>` on path A) and never changes once shared. The licence is theirs to choose: the template is MIT, so any licence works, open or commercial. Don't raise it unless they ask or mention selling; default to MIT and keep the template's MIT notice. If they plan to sell a closed-source plugin, a stock face is out (its art is GPL-3.0); use the placeholder face or their own art. Record the answers at the top of the spec (`templates/spec-template.md`); without files, keep the spec as a short block in the chat.

If the request is already specific ("a CE-2 chorus"), state your choices in two lines and build. Keep questions to the ones that change the plugin.

**Once it sounds right: the face.** After they've played a build and the sound works, offer in one line: *"Want it to look like a real pedal? I can give it a face."* Then one question: *what should it look like?*
- **Compact stompbox** with the big rocker footswitch (Boss-like): `japanese`, up to 8 knobs.
- **Hammond-style box** (DIY builds, MXR-like): `boxy`, 1–8 knobs, a selector, or up to 12 sliders. It widens for more controls.
- **Metal British box:** `british`, up to 4 knobs. **Tin can:** `lata`, up to 8 knobs.
- **Their own artwork:** a custom face (`docs/modgui.md`), after the sound works.


Plus a colour. You work out the size: the knob count picks the panel, and every extra footswitch they'd stomp (Tails, Hold, Tap) widens the box. Check what fits with `tools/stock_face.py <bundle> --style <s> --dry-run` before proposing. Without a shell, offer it too: the recipe downloads MOD's template and art while it builds ("A stock pedal face in a single `.mk`" above; verified on builder.mod.audio and a Duo). Knob-only panels that way. If a build ever fails with "face: could not download", ship the next build without the face and say why. Each upload gets a new build number, so a face added later shows up properly.

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
- Once the sound is right, a face is offered (stock, placeholder or their art). Before that, no face is fine: the build number changes every upload, so the face arrives cleanly when added.
- CHANGELOG, README and spec say what changed and why, with measured numbers where you have them.
- Anything not verified is said plainly ("not tested on hardware", "CPU estimate only", "compiled against a stand-in, not DPF").
- Loudness at the default settings is measured against bypass (average level, not peaks) and within ±3 dB, unless the spec says otherwise.

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
| `docs/dsp.md` | DSP rules for every plugin |
| `docs/dsp-*.md` | DSP by trait: `time` (delay, chorus, flanger, feedback), `reverb`, `drive`, `envelope`, `pitch` |
| `docs/testing.md` | The test rig and what to test |
| `docs/modgui.md` | Pedal faces |
| `docs/hardware-feedback.md` | Turning "it sounds wrong" into a fix |
| `docs/lessons.md` | Every rule with the incident behind it |
| `docs/known-mod-issues.md` | MOD-side bugs that look like plugin bugs |
| `docs/presets.md` | Factory presets, and carrying over presets made on a unit |
| `templates/plugin/` | A complete, tested template plugin (both paths) |
| `templates/spec-template.md`, `templates/hardware-report.md` | Fill-in templates |
| `examples/simple-echo.mk` | The template assembled into a single-file recipe: the shape to copy (generated) |
| `cookbook/` | Copies of MOD's cookbook prompt and examples (MIT), refreshed by `tools/make_all_in_one.py` |
| `ALL-IN-ONE.md` | Generated (`tools/make_all_in_one.py`): this file, the cookbook prompt, the key docs and the template, for chats that can't fetch. Re-run it after changing any of them |
| `tools/` | bump_links.py, make_all_in_one.py, check.sh, assemble_recipe.py, harness.mk, package_harness.mk, lv2host.c, lv2test.py, ttlcmp.py, bench.py, placeholder_face.py, stock_face.py, render_face.py, face_click_test.py, presets_from_device.py, knob_filmstrip.py, add_dpf_submodule.sh |
