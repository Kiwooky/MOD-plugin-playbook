# Lessons (each rule with the incident behind it)

Agents follow rules better when they know why. Add to this file whenever something costs you a round trip. Format: **Rule.** What happened. Where the rule now lives.

## Build and packaging

- **Declare `opts:options` and `urid:map` as required.** The cookbook's examples omit them and only work because mod-host supplies both; strict hosts refuse the plugin. (`lv2-and-mod-rules.md`)
- **Nothing over ~100 KB through `export`.** Taj Mahal's face broke the cookbook's `export` + `printf` pattern with "Argument list too long" (128 KB environment-variable limit). Switched to `$(file)` + base64. (`path-a-single-recipe.md`)
- **Bump the version on every upload, and ship a face from the first one.** Taj Mahal kept the default "tuna can" thumbnail: the first, face-less install was cached in the browser until 2035 under that version. (`lv2-and-mod-rules.md`)
- **The recipe filename must match its variable prefix.** The builder rewrites the prefix internally. (`path-a-single-recipe.md`)
- **Vendor DPF including `utils/symbols`.** The first vendoring script for this playbook left it out and the link step failed; caught by building the template as a repo. (`tools/vendor_dpf.sh`)
- **The package file needs the full 40-character commit hash.** (`path-b-github-repo.md`)
- **Compare the hand-written TTL with DPF's generator on every build.** It is the only check that the code and the metadata agree. (`tools/ttlcmp.py`)
- **Build the path-B package `.mk` locally before its first upload, with `TARGET_DIR` set inside the harness.** MultiPlay's first local package build failed at the bundle step: `TARGET_DIR` passed on the make command line overrode DPF's own `TARGET_DIR` in every sub-make, so the plugin binary landed elsewhere. In tests. (`tools/package_harness.mk`, `path-b-github-repo.md`)
- **A vendored-DPF repo is about 200 files; GitHub's web uploader takes 100.** MultiPlay's first push went through GitHub Desktop, and dragging the folder in Finder left the hidden `.gitignore` behind. Verified. (`path-b-github-repo.md`)
- **`scp` from a recent Mac needs `-O` to reach a MOD.** Fetching EC-280's presets failed with "subsystem request failed on channel 0": macOS `scp` now uses SFTP, which the MOD doesn't serve. Verified. (`presets.md`)
- **The agent can find the commit hash itself:** `git ls-remote https://github.com/<owner>/<repo>` works on a public repo without credentials. Verified. (`path-b-github-repo.md`)

## DSP and sound

- **Measure before you claim.** Can-Abyss's CPU was first predicted "well under Taj Mahal"; it measured 1.25×, later 0.7× after removing the noise section, then 1.2× with oversampling. Only measurements went into the docs after that. (`dsp.md`)
- **Players want movement, not dirt.** Modelled hiss and hum were switched off within seconds in the first hardware test; the warble they made in the tails was the part worth keeping. (`dsp.md`)
- **Test at guitar level.** Sag was tuned for hot signals and barely reacted to a guitar at about −20 dBFS. (`testing.md`)
- **Soft-knee the outputs.** 1.0.2's runaway peaked at +3.8 dBFS and hard-clipped at the converter: "digital ticks". (`dsp.md`)
- **Oversample saturators inside feedback loops.** Short-time runaways re-sharpened and aliased their own edges every lap. (`dsp.md`)
- **Map feedback edges on a grid, and make the edge playable.** A "one runaway path" fix moved Can-Abyss's runaway point to Repeat 9.3; on hardware it "would not oscillate any more". A Repeat × Reverb grid put the edge across several knob positions. (`dsp.md`, `testing.md`)
- **Scale speed modulation by speed.** A fixed percentage of delay time wobbled long delays five times harder; stock warble went from 20 cents RMS (seasick) to a steady 4.5. (`dsp.md`)
- **Model a compander with the compressor sensing its own output.** MultiPlay's NE570 model first sensed the compressor's input: every attack came out about +16 dB hot because the expander couldn't track it. With the rectifier on the output (as in the chip), compressor and expander cancel even during attacks. In tests. (`dsp.md`)
- **Two outputs with opposite-polarity wet cancel when summed to mono.** MultiPlay's Output 2 (stereo width, as on the original) loses its echoes if both outputs reach one mono input; the MOD sums several connections into one input. Believed (standard JACK summing). (`dsp.md`)
- **Land one-pole smoothers on their target.** EC-280's "dry at unity" measured 1 + 3e-5 with Volume above 5: in float the last steps are too small to register. Snap at the end of the block. In tests. (`dsp.md`)
- **A noise floor plus any loop gain above 1, at any frequency, self-oscillates.** EC-280's loop ran away from its own hiss at Duration 7.7, below unity at DC, because the in-loop filters peak slightly. "Soft stays stable, hard tips over" needs gain that rises with level, not a compressive clip. In tests. (`dsp.md`)
- **Model resistor mixing networks as passive buses.** Plain summing made EC-280's stacked buttons far too loud; V = Σ(G·V) ÷ (ΣG + G_load) makes combinations fuller but less than additive, as on the hardware. In tests. (`dsp.md`)
- **Two controls that sound alike are a design bug, not a user problem.** Repeat and Reverb both made clean repeats about 11% apart; Reverb became a diffused wash. (`hardware-feedback.md`)

- **Round, don't truncate, values that recirculate.** Taj Mahal's 16-bit "Vintage" tank first truncated toward zero: decay fell from 5.5 to 4.0 s, worse at 96 kHz. Rounding kept it. In tests. (`dsp.md`)
- **Time knobs read true end to end.** Taj Mahal's pre-delay of 81 ms arrived at 89.9 ms because the chorus in front adds 8 ms; subtracting it measured 81.9 ms. In tests. (`dsp.md`)
- **Derive reverb loop gain from a target RT60, and scale lengths from the reference rate.** Taj Mahal's RT60 stayed within ±0.1 s at 44.1, 48 and 96 kHz. In tests. (`dsp.md`)

## Testing

- **Smooth-enveloped test signals.** The first tick hunt flagged the test signal's own abrupt starts. (`testing.md`)
- **Validate detectors.** The first tick detector counted bright pluck onsets as ticks; the fix measures treble *share* and was checked against planted clicks and clean input. (`tools/lv2test.py`)
- **Measure delay times by cross-correlating a noise burst, not by threshold onset.** MultiPlay's onset test read its 1.2 ms flanger setting as "no echo": the compander's 4.7 ms envelope swallowed a 0.4 ms burst. A 30 ms noise burst and cross-correlation measured all 12 range × knob × Time Mod cases within 2 % (or 0.15 ms). In tests. (`testing.md`)
- **Test faces with mod-ui's own widget code.** MultiPlay's Repeat Hold footswitch "only responded once" on a Duo. Loading mod-ui's `modgui.js` and jQuery 1.9.1 in headless Chromium and clicking with a 2 px wobble reproduced it exactly. Verified on hardware and in tests. (`tools/face_click_test.py`)
- **Compare ARM with x86 by envelope in clock-phase code.** EC-280's ARM builds matched each other but differed from x86 by up to 0.8 sample-for-sample after 0.5 s: ARM GCC fuses multiply-adds, so a clock tick lands one sample differently. The 100 ms envelope agreed within 0.1 dB. In tests. (`testing.md`)
- **A test stand-in must behave like the platform.** `face_click_test.py` sent the face script a `change` for its own `set_port_value` and a fresh `event.data` every call; mod-ui does neither. A script relying on either would pass the test and fail on a unit. Fixed in 0.3.0, checked against `modgui.js`. (`modgui.md`)
- **Make the gate fail on purpose once.** The first "warning" check passed only because the planted bug hadn't been applied. (`testing.md`)

## Faces and controls

- **Buttons use `mod-widget="switch"`.** The default film widget drops clicks when the mouse moves slightly. (`modgui.md`)
- **Run the face click test before blaming the device.** EC-280 1.0.1 was built without this playbook. On a Duo, its film-widget switches "switched once, then never back" and Tail never moved; the agent first suspected a stale cache, and its own harness clicked each control once, cleanly, so it passed. `face_click_test.py` reproduces the failure exactly: the 2 px wobble drops the click. Verified on a Duo and in tests. (`modgui.md`)
- **The face click test must see script-driven controls.** EC-280's fix moved its switches and button banks to the face script (plain elements, no `mod-role`), which the 0.2.0 tool skipped. It now finds them by the attribute naming their port and presses them with mouse, wobble and touch. In tests: passes EC-280 1.0.0, fails three switches with an emptied handler. (`tools/face_click_test.py`)
- **A face script gets no `change` for its own `set_port_value`.** It must redraw its own lamps; footswitch, MIDI and preset changes do arrive as `change`. Source-checked, in tests. (`modgui.md`)
- **Radio buttons with "hold to add": one bitmask port per bank.** EC-280's push-button banks are radio, but latch several if pressed together. One integer port (1–15, labelled scale points) plus a face script (tap = one, hold = add/remove, never empty) keeps the unit's screen, footswitch stepping and presets working. In tests, mouse and touch. (`modgui.md`)
- **Measure the printed knob scale before building the filmstrip.** EC-280's artwork spans 276°, not 270°; a sweep measured from the background put the pointer on every number. Render-checked. (`modgui.md`)
- **Fit control positions to the designer's mockup by template matching.** Zero pixel error for every EC-280 button and switch. In tests. (`modgui.md`)
- **Latching unless asked.** Hold was copied with `mod:preferMomentaryOnByDefault` from another plugin's switch; the player wanted latching. (`lv2-and-mod-rules.md`)
- **The bypass widget's classes are inverted** (`on` = bypassed). (`modgui.md`)
- **A multi-position switch drawn as a film only steps forward and wraps.** MultiPlay's range lever went 2 s → 16 ms → 250 ms whichever legend line was clicked (hardware). Fix: transparent click zones over each position that call `funcs.set_port_value` from the face script; the film still draws the lever. Fix verified with mod-ui's code in tests. (`modgui.md`)
- **Render the screenshot after rebuilding the bundle.** MultiPlay's first re-render after a new background read the old one from the build output. (`modgui.md`)

- **Read what's installed before theorising.** Taj Mahal's tuna can survived a "v1.0.2 reinstall"; a duplicate-bundle theory and a reboot both went nowhere. `/effect/get` showed `version 0.0`, `stability: experimental`: an older file had been uploaded. Verified on a Duo. (`known-mod-issues.md`)

## Bypass, presets and identity

- **Bypass puts the dry at unity whatever Mix says.** MultiPlay faded the wet out but kept Mix's dry gain, so at full wet, bypass went silent (found on a Duo). Fade the dry gain to 1 alongside the wet. Fixed and tested. (`lv2-and-mod-rules.md`)
- **Ask what the original's bypass did before adding Tails.** On MultiPlay's original the delay kept running under bypass and a held loop came back when the effect was switched on; the owner wanted that, not a Tails switch. (`lv2-and-mod-rules.md`)
- **Changing the URI orphans every preset and pedalboard saved with the old one.** MultiPlay's ten presets were made on the cookbook prototype (`urn:mod-cookbook:multiplay`); the repo version has a new URI. They were fetched from the Duo and shipped as factory presets. Verified on a Duo. (`presets.md`, `tools/presets_from_device.py`)
- **Leave footswitch states out of factory presets.** One preset had been saved with Repeat Hold on; loading it would freeze whatever happened to be in the buffer. (`presets.md`)
- **Preset folder names go stale; labels don't.** Renamed presets keep their original folder: Taj Mahal's `Early_wobble` folder held "Negative reflections". Verified on a Duo. (`presets.md`)
- **Check the licence GitHub put in the repo.** Taj Mahal's repo started with GPL-2 from GitHub's template while the code was MIT. (`path-b-github-repo.md`)
- **Tell people where a file will land.** `scp root@…:file .` left the presets "wherever the terminal was" and the person couldn't find them; `ssh … "tar czf - …" > ~/Desktop/name.tgz` puts them on the Desktop. (`presets.md`)

## Recreations

- **The owner's front panel beats a blurry schematic.** MultiPlay's scan suggested 512 / 16,384 / 65,536-sample ranges; the panel legend (16 ms / 250 ms / 2 s) showed the middle one is 8,192, a counter pin label one bit off. Ask for panel photos and legends at the start.
- **Settle an ambiguous schematic reading with one test the owner can hear.** EC-280's Echo buttons read two ways: "with E4 alone, is the first echo long then fluttering, or short?" on a demo video decided it. Verified by the owner.
- **Ask about mechanics a schematic can't show.** EC-280's button wiring allowed radio or additive; only the owner and a video knew (radio, latching if pressed together).
- **Read a scanned schematic from the PDF's embedded image at its native resolution.** Rasterising EC-280's 150 dpi scan at 300 dpi added nothing; cropping and zooming the embedded image read the resistor values.
- **Don't infer from another plugin's untested path.** "Taj Mahal's toggles work, so the film widget is fine" was wrong: they default to on and probably were never switched off on a unit.
- **Ask what the original did before you "fix" it.** Tails, Mix on Output 1, Output 2's polarity and the bypass all had answers only the owner had. Mark each schematic reading *confident*, *approximate* or *guess*, and let the owner overrule.
