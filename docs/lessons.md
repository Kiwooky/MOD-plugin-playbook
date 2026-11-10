# Lessons (each rule with the incident behind it)

Agents follow rules better when they know why. Add to this file whenever something costs you a round trip. Format: **Rule.** What happened. Where the rule now lives.

The incidents come from five plugins built while writing this playbook: a hall reverb, a bucket-brigade (BBD) echo, an early digital delay with a compander, an oil-can delay, and Trance Atlantic (an envelope pitch swoop into an underwater reverb). DSP rules now live in `dsp.md` (every plugin) and per-trait files (`dsp-time.md`, `dsp-reverb.md`, `dsp-drive.md`, `dsp-envelope.md`, `dsp-pitch.md`).

## Build and packaging

- **Declare `opts:options` and `urid:map` as required.** The cookbook's examples omit them and only work because mod-host supplies both; strict hosts refuse the plugin. (`lv2-and-mod-rules.md`)
- **Nothing over ~100 KB through `export`.** The hall reverb's face broke the cookbook's `export` + `printf` pattern with "Argument list too long" (128 KB environment-variable limit). Switched to `$(file)` + base64. (`path-a-single-recipe.md`)
- **Bump the version on every upload, and ship a face from the first one.** The hall reverb kept the default "tuna can" thumbnail: the first, face-less install was cached in the browser until 2035 under that version. (`lv2-and-mod-rules.md`)
- **A single recipe's `_VERSION` is DPF's commit.** Tapestry's had its repo commit pasted in, as a package file wants, and the build failed. Once a plugin is on GitHub, use path B only. (`path-a-single-recipe.md`)
- **The recipe filename must match its variable prefix.** The builder rewrites the prefix internally. (`path-a-single-recipe.md`)
- **Use DPF as a git submodule, the way MOD's own packages do.** Earlier versions vendored a copy of DPF into each repo, believing the builder couldn't fetch submodules. A plugin developer pointed out that's non-standard. mod-plugin-builder has a hook for it (`MOD_PLUGIN_BUILDER_DOWNLOAD_WITH_SUBMODULES`), used by 26 of MOD's packages; a test recipe proved builder.mod.audio runs it. Check how the platform's own packages solve a problem before working around it. Verified on builder.mod.audio. (`path-b-github-repo.md`)
- **The package file needs the full 40-character commit hash.** (`path-b-github-repo.md`)
- **Compare the hand-written TTL with DPF's generator on every build.** It is the only check that the code and the metadata agree. (`tools/ttlcmp.py`)
- **Build the path-B package `.mk` locally before its first upload, with `TARGET_DIR` set inside the harness.** The digital delay's first local package build failed at the bundle step: `TARGET_DIR` passed on the make command line overrode DPF's own `TARGET_DIR` in every sub-make, so the plugin binary landed elsewhere. In tests. (`tools/package_harness.mk`, `path-b-github-repo.md`)
- **builder.mod.audio silently refuses recipes near 1 MB.** Trance Atlantic's 998 KB `.mk` went from "preparing" straight to "ready" with no error; 888 KB had built. A single overlay re-saved as full RGBA (157 KB, 41 KB as 256-colour) had pushed it over. Verified on the builder. (`path-a-single-recipe.md`, `modgui.md`)
- **An agent without push access can still deliver a commit:** a git bundle copied into the person's clone, fetched and fast-forwarded there; they push. A bundle regenerated under the same name in the same batch arrived as the old copy: use a new name. Verified. (`path-b-github-repo.md`)
- **GitHub's web uploader takes 100 files and can't add submodules.** The digital delay's first push went through GitHub Desktop, and dragging the folder in Finder left the hidden `.gitignore` behind. Verified. (`path-b-github-repo.md`)
- **`scp` from a recent Mac needs `-O` to reach a MOD.** Fetching the BBD echo's presets failed with "subsystem request failed on channel 0": macOS `scp` now uses SFTP, which the MOD doesn't serve. Verified. (`presets.md`)
- **Look for deletions before committing.** The oil-can delay's TTL files vanished when a folder was replaced in Finder from a zip; the pinned build failed until they were restored from history. Verified in git history. (`path-b-github-repo.md`)
- **The agent can find the commit hash itself:** `git ls-remote https://github.com/<owner>/<repo>` works on a public repo without credentials. Verified. (`path-b-github-repo.md`)

## DSP and sound

- **Measure before you claim.** The oil-can delay's CPU was first predicted "well under the hall reverb"; it measured 1.25×, later 0.7× after removing the noise section, then 1.2× with oversampling. Only measurements went into the docs after that. (`dsp.md`)
- **One Noise control, and 0 means none.** Tapestry's Hiss at 0 still rasped: tape grain, not hiss. Grain and hiss on one knob kept everyone happy. (`dsp.md`)
- **Share the mechanism, split the noise, link the detectors** when making a mono effect stereo; keep the left on the mono seed so left = mono. (`dsp.md`)
- **Tilt with a shelf.** A low-pass/high-pass crossfade bumped the mids. (`dsp.md`)
- **Players want movement, not dirt.** Modelled hiss and hum were switched off within seconds in the first hardware test; the warble they made in the tails was the part worth keeping. (`dsp.md`)
- **Test at guitar level.** Sag was tuned for hot signals and barely reacted to a guitar at about −20 dBFS. (`testing.md`)
- **Soft-limit effects that can run away (wet path).** The oil-can delay 1.0.2's runaway peaked at +3.8 dBFS and hard-clipped at the converter: "digital ticks". (`dsp.md`, `dsp-time.md`)
- **Oversample saturators inside feedback loops.** Short-time runaways re-sharpened and aliased their own edges every lap. (`dsp-time.md`)
- **Map feedback edges on a grid, and make the edge playable.** A "one runaway path" fix moved the oil-can delay's runaway point to Repeat 9.3; on hardware it "would not oscillate any more". A Repeat × Reverb grid put the edge across several knob positions. (`dsp-time.md`, `testing.md`)
- **Scale speed modulation by speed.** A fixed percentage of delay time wobbled long delays five times harder; stock warble went from 20 cents RMS (seasick) to a steady 4.5. (`dsp-time.md`)
- **Model a compander with the compressor sensing its own output.** The digital delay's NE570 model first sensed the compressor's input: every attack came out about +16 dB hot because the expander couldn't track it. With the rectifier on the output (as in the chip), compressor and expander cancel even during attacks. In tests. (`dsp-time.md`)
- **Two outputs with opposite-polarity wet cancel when summed to mono.** The digital delay's Output 2 (stereo width, as on the original) loses its echoes if both outputs reach one mono input; the MOD sums several connections into one input. Believed (standard JACK summing). (`dsp.md`)
- **Land one-pole smoothers on their target.** The BBD echo's "dry at unity" measured 1 + 3e-5 with Volume above 5: in float the last steps are too small to register. Snap at the end of the block. In tests. (`dsp.md`)
- **A noise floor plus any loop gain above 1, at any frequency, self-oscillates.** The BBD echo's loop ran away from its own hiss at Duration 7.7, below unity at DC, because the in-loop filters peak slightly. "Soft stays stable, hard tips over" needs gain that rises with level, not a compressive clip. In tests. (`dsp-time.md`)
- **Model resistor mixing networks as passive buses.** Plain summing made the BBD echo's stacked buttons far too loud; V = Σ(G·V) ÷ (ΣG + G_load) makes combinations fuller but less than additive, as on the hardware. In tests. (`dsp.md`)
- **Two controls that sound alike are a design bug, not a user problem.** Repeat and Reverb both made clean repeats about 11% apart; Reverb became a diffused wash. (`hardware-feedback.md`)

- **Round, don't truncate, values that recirculate.** The hall reverb's 16-bit "Vintage" tank first truncated toward zero: decay fell from 5.5 to 4.0 s, worse at 96 kHz. Rounding kept it. In tests. (`dsp-reverb.md`)
- **Time knobs read true end to end.** The hall reverb's pre-delay of 81 ms arrived at 89.9 ms because the chorus in front adds 8 ms; subtracting it measured 81.9 ms. In tests. (`dsp-reverb.md`)
- **Derive reverb loop gain from a target RT60, and scale lengths from the reference rate.** The hall reverb's RT60 stayed within ±0.1 s at 44.1, 48 and 96 kHz. In tests. (`dsp-reverb.md`)

- **Research what makes a space distinct before tuning a tank.** Trance Atlantic's first underwater reverb was a darkened, warbly hall, and on a Duo it "sounded like a cave". Separate bounces, dispersion, a narrow image and a drifting inverted surface reflection made it read as water. By ear on a Duo. (`dsp-reverb.md`)
- **Drain the lows inside a dark tank.** Long, dark tails boomed; a high-pass in the loop fixed it, and shortened the measured RT60 (10 s set point → 5.7 s). In tests and by ear. (`dsp-reverb.md`)
- **Run band-limited sub-chains at a lower rate, and filter the upsampling.** A half-rate ocean cut CPU from 2.1× to 1.4× the hall reverb; plain linear upsampling left images that `tick_count` caught. In tests and the benchmark. (`dsp.md`)
- **Pitch from a moving delay: up costs latency, down must stay above zero speed.** A two-octave upward swoop was heard at about +17 semitones, late; sizing dives with (r − 1) instead of (1 − 1/r) would have read backwards. In tests. (`dsp-pitch.md`)
- **Filter before the bend.** A deep dive fell out of the following band-pass and vanished. In tests. (`dsp-pitch.md`)
- **Don't remove a control that "does nothing" on one instrument.** A width-only filter knob did little on guitar; as a centred range shift it serves bass. On a Duo. (`dsp-envelope.md`)

## Testing

- **Smooth-enveloped test signals.** The first tick hunt flagged the test signal's own abrupt starts. (`testing.md`)
- **Validate detectors.** The first tick detector counted bright pluck onsets as ticks; the fix measures treble *share* and was checked against planted clicks and clean input. (`tools/lv2test.py`)
- **Measure delay times by cross-correlating a noise burst, not by threshold onset.** The digital delay's onset test read its 1.2 ms flanger setting as "no echo": the compander's 4.7 ms envelope swallowed a 0.4 ms burst. A 30 ms noise burst and cross-correlation measured all 12 range × knob × Time Mod cases within 2 % (or 0.15 ms). In tests. (`testing.md`)
- **Test faces with mod-ui's own widget code.** The digital delay's Repeat Hold footswitch "only responded once" on a Duo. Loading mod-ui's `modgui.js` and jQuery 1.9.1 in headless Chromium and clicking with a 2 px wobble reproduced it exactly. Verified on hardware and in tests. (`tools/face_click_test.py`)
- **Compare ARM with x86 by envelope in clock-phase code.** The BBD echo's ARM builds matched each other but differed from x86 by up to 0.8 sample-for-sample after 0.5 s: ARM GCC fuses multiply-adds, so a clock tick lands one sample differently. The 100 ms envelope agreed within 0.1 dB. In tests. (`testing.md`)
- **A test stand-in must behave like the platform.** `face_click_test.py` sent the face script a `change` for its own `set_port_value` and a fresh `event.data` every call; mod-ui does neither. A script relying on either would pass the test and fail on a unit. Fixed in 0.3.0, checked against `modgui.js`. (`modgui.md`)
- **Envelope filters need harmonic test signals.** Pure-sine plucks left Trance Atlantic's throat test reading 200 Hz whatever the playing; harmonic plucks showed it opening from 250 to 430 Hz. In tests. (`tools/lv2test.py`, `dsp-envelope.md`)
- **Know where a detector reads false.** `tick_count` flagged 2 ms harmonic attacks and octave-shifted partials at −90 dBFS; zero-crossing pitch tracking spiked where two paths cancelled and read silence as −800 cents. Check the input first, use 5 ms attacks, medians and longer windows for low notes. In tests. (`testing.md`, `dsp-pitch.md`)
- **Compare floats with a tolerance, blank nodes by content, and a custom unit with DPF's stock unit by symbol.** `ttlcmp.py` failed on a custom unit (blank-node IDs differ every parse), on a default of 80.71 (DPF writes float32: 80.7099990845), and on the oil-can delay's `%.0fms` display format against DPF's `units:ms`. In tests. (`tools/ttlcmp.py`)
- **Make the gate fail on purpose once.** The first "warning" check passed only because the planted bug hadn't been applied. (`testing.md`)
- **fast-math: one source, two builds, not bit-identical.** Tapestry Stereo's left side vs mono: −65 to −96 dB; identical without `-ffast-math`. Test against a bar. (`testing.md`)

## Faces and controls

- **Live values reach a face only through `modgui:monitoredOutputs`, and only while MOD's feedback is flowing.** Trance Atlantic's ripples showed nothing on a Duo; the 10-second websocket tally showed only `ping` and `stats`: the 1.14 `data_ready` stall, not the plugin. Releasing it brought the values. Verified on a Duo. (`modgui.md`, `known-mod-issues.md`)
- **A faint layer times a typical meter value is invisible.** 25% art opacity × 0.3 ≈ 8%. Tune the meter mapping and the art together. On a Duo. (`modgui.md`)
- **A face font needs `!important`.** mod-ui's `main.css` forces its own font on every element with `!important`; that was why a dafont TTF "didn't render" on the unit. With `!important` Tapestry's LCD font rendered on a Duo; image strips remain the fallback. (`modgui.md`)
- **Film elements in whole pixels.** A 63.5 px knob drifted across frames; 64 px fixed it. (`modgui.md`)
- **mod-ui's film widget reads horizontal strips only.** A vertical HISE knob export had to be rotated into a row. Checked in `modgui.js`. (`modgui.md`)
- **Step buttons aren't pick buttons.** `face_click_test.py` failed Travel and Mode buttons because a step's value depends on the state; it now presses step buttons (an attribute name containing `step`) and checks every press moves. In tests. (`tools/face_click_test.py`)
- **Tempo sync is one TTL property; check the platform before adding ports.** Asked for BPM time entry, the oil-can delay's first plan was extra settings ports; `mod:tempoRelatedDynamicScalePoints` gives mod-ui's own Tempo + note value. Source-checked. (`lv2-and-mod-rules.md`)
- **Tap tempo can only be the pedalboard's.** mod-ui offers footswitch tap-tempo only on the global `:bpm` port; a plugin Tap control would leave the Time knob showing the wrong time. Source-checked. (`lv2-and-mod-rules.md`)
- **Type into a script-drawn `<input>`, not mod-ui's `input-control-value`.** The oil-can delay's readouts showed values but took no typing on a Duo. Failure verified on a Duo; fix in tests. (`modgui.md`)
- **Give a 2× strip's `background-size` an explicit height.** mod-ui counts frames from that height; without it, a 2× strip reads double the frames. Source-checked. (`modgui.md`)
- **Sliders are invisible film strips plus a script.** The oil-can delay's Disc Size slider scales a can from 140 to 280 px; 201 frames gives 1 px per step of mod-ui's drag. In tests. (`modgui.md`)
- **One strip for a button and its LED.** The oil-can delay's four switches light their LEDs with no script. In tests. (`modgui.md`)
- **Ship the designer's background JPEG untouched.** A re-saved panel smeared the oil-can delay's logo. By eye. (`modgui.md`)
- **Ask which image is the default state.** The first build drew the buttons pressed at rest. (`modgui.md`)

- **Buttons use `mod-widget="switch"`.** The default film widget drops clicks when the mouse moves slightly. (`modgui.md`)
- **Run the face click test before blaming the device.** The BBD echo 1.0.1 was built without this playbook. On a Duo, its film-widget switches "switched once, then never back" and Tail never moved; the agent first suspected a stale cache, and its own harness clicked each control once, cleanly, so it passed. `face_click_test.py` reproduces the failure exactly: the 2 px wobble drops the click. Verified on a Duo and in tests. (`modgui.md`)
- **The face click test must see script-driven controls.** The BBD echo's fix moved its switches and button banks to the face script (plain elements, no `mod-role`), which the 0.2.0 tool skipped. It now finds them by the attribute naming their port and presses them with mouse, wobble and touch. In tests: passes the BBD echo 1.0.0, fails three switches with an emptied handler. (`tools/face_click_test.py`)
- **A face script gets no `change` for its own `set_port_value`.** It must redraw its own lamps; footswitch, MIDI and preset changes do arrive as `change`. Source-checked, in tests. (`modgui.md`)
- **Radio buttons with "hold to add": one bitmask port per bank.** The BBD echo's push-button banks are radio, but latch several if pressed together. One integer port (1–15, labelled scale points) plus a face script (tap = one, hold = add/remove, never empty) keeps the unit's screen, footswitch stepping and presets working. In tests, mouse and touch. (`modgui.md`)
- **Measure the printed knob scale before building the filmstrip.** The BBD echo's artwork spans 276°, not 270°; a sweep measured from the background put the pointer on every number. Render-checked. (`modgui.md`)
- **Fit control positions to the designer's mockup by template matching.** Zero pixel error for every button and switch on the BBD echo. In tests. (`modgui.md`)
- **Latching unless asked.** Hold was copied with `mod:preferMomentaryOnByDefault` from another plugin's switch; the player wanted latching. (`lv2-and-mod-rules.md`)
- **The bypass widget's classes are inverted** (`on` = bypassed). (`modgui.md`)
- **Pin fading layers to the compositor.** Two faces' orbs made the whole pedal flicker in brightness as the input level faded them; `will-change: opacity` on each layer fixed both on a Duo. (`modgui.md`)
- **Port order is the panel order.** Grouping Trance Atlantic's controls only labels them; MOD sorts by group `lv2:index` (DPF doesn't write it, so groups fell back to alphabetical) and then port index, which is also the order without group support. Renumbered the ports to match; checked with mod-ui's plugin-info code. (`lv2-and-mod-rules.md`)
- **A multi-position switch drawn as a film only steps forward and wraps.** The digital delay's range lever went 2 s → 16 ms → 250 ms whichever legend line was clicked (hardware). Fix: transparent click zones over each position that call `funcs.set_port_value` from the face script; the film still draws the lever. Fix verified with mod-ui's code in tests. (`modgui.md`)
- **Render the screenshot after rebuilding the bundle.** The digital delay's first re-render after a new background read the old one from the build output. (`modgui.md`)

- **Read what's installed before theorising.** The hall reverb's tuna can survived a "v1.0.2 reinstall"; a duplicate-bundle theory and a reboot both went nowhere. `/effect/get` showed `version 0.0`, `stability: experimental`: an older file had been uploaded. Verified on a Duo. (`known-mod-issues.md`)

## Bypass, presets and identity

- **`rdfs:seeAlso`, never `lv2:seeAlso`, in `manifest.ttl`.** A hand-written recipe from a chat without a shell used `lv2core#seeAlso`: MOD never read the plugin's TTL, so it installed with no name, category or controls and couldn't be removed from the UI. Installing a fixed build with the same bundle name replaced it. Reproduced with `lv2info` (0 ports, no name). (`AGENTS.md`, hand-written `.mk` checklist)

- **Rules learned on one kind of effect get scoped, not copied.** The first versions said "Tails on/off" and "soft-knee every output" for every plugin, because they came from delays. A gain pedal has no tail, and a knee on its output squashes the boost it exists for. Rules now carry the trait they apply to. (`effect-profile.md`)
- **Presets leave Mix alone.** A preset sets the sound, not the balance. (`presets.md`)
- **mod-host's own bypass is an instant switch.** It copies input to output from the next block, with no crossfade; on a processed signal that pops. An `lv2:enabled` port lets the plugin fade. Source-checked (mod-host `effects.c`). (`lv2-and-mod-rules.md`)

- **Bypass puts the dry at unity whatever Mix says.** The digital delay faded the wet out but kept Mix's dry gain, so at full wet, bypass went silent (found on a Duo). Fade the dry gain to 1 alongside the wet. Fixed and tested. (`lv2-and-mod-rules.md`)
- **Ask what the original's bypass did before adding Tails.** On the digital delay's original the delay kept running under bypass and a held loop came back when the effect was switched on; the owner wanted that, not a Tails switch. (`lv2-and-mod-rules.md`)
- **Changing the URI orphans every preset and pedalboard saved with the old one.** The digital delay's ten presets were made on the cookbook prototype (`urn:mod-cookbook:<name>`); the repo version has a new URI. They were fetched from the Duo and shipped as factory presets. Verified on a Duo. (`presets.md`, `tools/presets_from_device.py`)
- **Leave footswitch states out of factory presets.** One preset had been saved with Repeat Hold on; loading it would freeze whatever happened to be in the buffer. (`presets.md`)
- **Preset folder names go stale; labels don't.** Renamed presets keep their original folder: the hall reverb's `Early_wobble` folder held "Negative reflections". Verified on a Duo. (`presets.md`)
- **Check the licence GitHub put in the repo.** The hall reverb's repo started with GPL-2 from GitHub's template while the code was MIT. (`path-b-github-repo.md`)
- **Tell people where a file will land.** `scp root@…:file .` left the presets "wherever the terminal was" and the person couldn't find them; `ssh … "tar czf - …" > ~/Desktop/name.tgz` puts them on the Desktop. (`presets.md`)

## Recreations

- **The owner's front panel beats a blurry schematic.** The digital delay's scan suggested 512 / 16,384 / 65,536-sample ranges; the panel legend (16 ms / 250 ms / 2 s) showed the middle one is 8,192, a counter pin label one bit off. Ask for panel photos and legends at the start.
- **Settle an ambiguous schematic reading with one test the owner can hear.** The BBD echo's Echo buttons read two ways: "with E4 alone, is the first echo long then fluttering, or short?" on a demo video decided it. Verified by the owner.
- **Ask about mechanics a schematic can't show.** The BBD echo's button wiring allowed radio or additive; only the owner and a video knew (radio, latching if pressed together).
- **Read a scanned schematic from the PDF's embedded image at its native resolution.** Rasterising the BBD echo's 150 dpi scan at 300 dpi added nothing; cropping and zooming the embedded image read the resistor values.
- **Don't infer from another plugin's untested path.** "The hall reverb's toggles work, so the film widget is fine" was wrong: they default to on and probably were never switched off on a unit.
- **Ask what the original did before you "fix" it.** Tails, Mix on Output 1, Output 2's polarity and the bypass all had answers only the owner had. Mark each schematic reading *confident*, *approximate* or *guess*, and let the owner overrule.

## Working with the person

- **Images go as files, both ways.** A 2× knob strip pasted into chat arrived as 62×8000 without alpha; a folder-structured zip sent back deleted files when unpacked over the repo. (`process.md`)
- **Work in the person's clone when you can reach it.** Only reading the oil-can delay's clone showed its missing TTL files; sandbox copies drift. (`process.md`)
