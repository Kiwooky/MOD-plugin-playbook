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

## DSP and sound

- **Measure before you claim.** Can-Abyss's CPU was first predicted "well under Taj Mahal"; it measured 1.25×, later 0.7× after removing the noise section, then 1.2× with oversampling. Only measurements went into the docs after that. (`dsp.md`)
- **Players want movement, not dirt.** Modelled hiss and hum were switched off within seconds in the first hardware test; the warble they made in the tails was the part worth keeping. (`dsp.md`)
- **Test at guitar level.** Sag was tuned for hot signals and barely reacted to a guitar at about −20 dBFS. (`testing.md`)
- **Soft-knee the outputs.** 1.0.2's runaway peaked at +3.8 dBFS and hard-clipped at the converter: "digital ticks". (`dsp.md`)
- **Oversample saturators inside feedback loops.** Short-time runaways re-sharpened and aliased their own edges every lap. (`dsp.md`)
- **Map feedback edges on a grid, and make the edge playable.** A "one runaway path" fix moved Can-Abyss's runaway point to Repeat 9.3; on hardware it "would not oscillate any more". A Repeat × Reverb grid put the edge across several knob positions. (`dsp.md`, `testing.md`)
- **Scale speed modulation by speed.** A fixed percentage of delay time wobbled long delays five times harder; stock warble went from 20 cents RMS (seasick) to a steady 4.5. (`dsp.md`)
- **Two controls that sound alike are a design bug, not a user problem.** Repeat and Reverb both made clean repeats about 11% apart; Reverb became a diffused wash. (`hardware-feedback.md`)

## Testing

- **Smooth-enveloped test signals.** The first tick hunt flagged the test signal's own abrupt starts. (`testing.md`)
- **Validate detectors.** The first tick detector counted bright pluck onsets as ticks; the fix measures treble *share* and was checked against planted clicks and clean input. (`tools/lv2test.py`)
- **Make the gate fail on purpose once.** The first "warning" check passed only because the planted bug hadn't been applied. (`testing.md`)

## Faces and controls

- **Buttons use `mod-widget="switch"`.** The default film widget drops clicks when the mouse moves slightly. (`modgui.md`)
- **Latching unless asked.** Hold was copied with `mod:preferMomentaryOnByDefault` from another plugin's switch; the player wanted latching. (`lv2-and-mod-rules.md`)
- **The bypass widget's classes are inverted** (`on` = bypassed). (`modgui.md`)
