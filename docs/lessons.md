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
- **Two controls that sound alike are a design bug, not a user problem.** Repeat and Reverb both made clean repeats about 11% apart; Reverb became a diffused wash. (`hardware-feedback.md`)

## Testing

- **Smooth-enveloped test signals.** The first tick hunt flagged the test signal's own abrupt starts. (`testing.md`)
- **Validate detectors.** The first tick detector counted bright pluck onsets as ticks; the fix measures treble *share* and was checked against planted clicks and clean input. (`tools/lv2test.py`)
- **Measure delay times by cross-correlating a noise burst, not by threshold onset.** MultiPlay's onset test read its 1.2 ms flanger setting as "no echo": the compander's 4.7 ms envelope swallowed a 0.4 ms burst. A 30 ms noise burst and cross-correlation measured all 12 range × knob × Time Mod cases within 2 % (or 0.15 ms). In tests. (`testing.md`)
- **Test faces with mod-ui's own widget code.** MultiPlay's Repeat Hold footswitch "only responded once" on a Duo. Loading mod-ui's `modgui.js` and jQuery 1.9.1 in headless Chromium and clicking with a 2 px wobble reproduced it exactly. Verified on hardware and in tests. (`tools/face_click_test.py`)
- **Make the gate fail on purpose once.** The first "warning" check passed only because the planted bug hadn't been applied. (`testing.md`)

## Faces and controls

- **Buttons use `mod-widget="switch"`.** The default film widget drops clicks when the mouse moves slightly. (`modgui.md`)
- **Latching unless asked.** Hold was copied with `mod:preferMomentaryOnByDefault` from another plugin's switch; the player wanted latching. (`lv2-and-mod-rules.md`)
- **The bypass widget's classes are inverted** (`on` = bypassed). (`modgui.md`)
- **A multi-position switch drawn as a film only steps forward and wraps.** MultiPlay's range lever went 2 s → 16 ms → 250 ms whichever legend line was clicked (hardware). Fix: transparent click zones over each position that call `funcs.set_port_value` from the face script; the film still draws the lever. Fix verified with mod-ui's code in tests. (`modgui.md`)
- **Render the screenshot after rebuilding the bundle.** MultiPlay's first re-render after a new background read the old one from the build output. (`modgui.md`)

## Bypass, presets and identity

- **Bypass puts the dry at unity whatever Mix says.** MultiPlay faded the wet out but kept Mix's dry gain, so at full wet, bypass went silent (found on a Duo). Fade the dry gain to 1 alongside the wet. Fixed and tested. (`lv2-and-mod-rules.md`)
- **Ask what the original's bypass did before adding Tails.** On MultiPlay's original the delay kept running under bypass and a held loop came back when the effect was switched on; the owner wanted that, not a Tails switch. (`lv2-and-mod-rules.md`)
- **Changing the URI orphans every preset and pedalboard saved with the old one.** MultiPlay's ten presets were made on the cookbook prototype (`urn:mod-cookbook:multiplay`); the repo version has a new URI. They were fetched from the Duo and shipped as factory presets. Verified on a Duo. (`presets.md`, `tools/presets_from_device.py`)
- **Leave footswitch states out of factory presets.** One preset had been saved with Repeat Hold on; loading it would freeze whatever happened to be in the buffer. (`presets.md`)
- **Tell people where a file will land.** `scp root@…:file .` left the presets "wherever the terminal was" and the person couldn't find them; `ssh … "tar czf - …" > ~/Desktop/name.tgz` puts them on the Desktop. (`presets.md`)

## Recreations

- **The owner's front panel beats a blurry schematic.** MultiPlay's scan suggested 512 / 16,384 / 65,536-sample ranges; the panel legend (16 ms / 250 ms / 2 s) showed the middle one is 8,192, a counter pin label one bit off. Ask for panel photos and legends at the start.
- **Ask what the original did before you "fix" it.** Tails, Mix on Output 1, Output 2's polarity and the bypass all had answers only the owner had. Mark each schematic reading *confident*, *approximate* or *guess*, and let the owner overrule.
