# Effect profile: where the idea starts, and what it needs

Rules in this playbook were learned on specific effects. Some apply to every plugin, most apply only to effects with a certain trait. Work out the starting point first, then the traits; together they decide the research, the rules, the tests and how much of the template survives.

## 1. Where the idea starts

Ask once, in the kick-off. The answer decides what you gather before any code.

| Starting point | Example | Gather first | The concept paragraph answers |
| --- | --- | --- | --- |
| **Imagined:** no prior art | "Chinese whispers": a delay where each repeat re-interprets the last, with errors | What it should *feel* like, in their words; one or two reference sounds it's near (even unrelated ones); what must never happen | Which known building blocks make it, in what order, and which knob shapes the character. Mark everything *our idea*. |
| **Reference sound:** a sound people know | "Eddie Van Halen's phaser" | Research it: the gear (an MXR Phase 90; the early "script logo" version), how it works (four all-pass stages and one LFO; the script version leaves out the feedback resistor the later ones added, which is much of its smoother sound), recordings to compare against. Confirm the gear with the person before building. | What makes it sound like itself, with a source per claim. Mark *documented*, *commercial model* or *guess*. |
| **Specific gear:** a unit, often with schematics | A 1980s echo with the service manual | Schematics, front-panel photos and legends, the manual, recordings or videos, and the owner's memory of how it behaves | How the original works, stage by stage. Mark each reading *confident*, *approximate* or *guess*; the owner overrules (`docs/lessons.md`, Recreations). |

Search the web for reference sounds even when you think you know the gear; the person's memory and yours can both be wrong. For specific gear, ask for the panel and the manual at the start: they settle what a blurry schematic can't.

## 2. The traits

Tick these at the end of the concept stage and put them at the top of the spec. Each brings its rules, its tests and its part of the template. Leave out what isn't ticked.

| Trait | Typical effects | Rules it brings | Tests it brings |
| --- | --- | --- | --- |
| **Every plugin** | all | Real-time `run()` (no allocation, locks, I/O); controls snapped on the first `run()`, then smoothed; sample-rate-scaled time constants; in-plugin bypass with a short crossfade (`lv2-and-mod-rules.md`); version bump on every upload | Tuning/timing at 44.1, 48, 96 kHz; levels per spec; bypass is click-free with dry at unity; torture (finite); silence in, silence out |
| **Has a tail** (sound continues after the input stops) | delay, reverb, looper, long-decay filters | Tails on/off option; Tails off clears state without a click | Bypass with Tails on (tail rings out) and off (wet fades) |
| **Feedback loop** (output fed back into itself) | delay, reverb, flanger, resonant filter, phaser with regen | Denormal guard; cap loop bandwidth; oversample a saturator inside the loop; map the runaway edge on a grid; **soft limit on the wet path** so a runaway can't hit the converter | Runaway grid; torture at max feedback stays under 0 dBFS; no ticks with plucks |
| **Has a buffer** (stores audio) | delay, chorus, flanger, reverb, looper, pitch | Allocate in the constructor, sized for 96 kHz; power-of-two with a mask; clear in `activate()` | Timing at three rates |
| **Nonlinear / gain** (adds harmonics or boosts) | boost, overdrive, fuzz, distortion, saturation, amp-like | **No output knee:** the clipping curve is the sound, and a boost is meant to exceed the input. Oversample the nonlinearity (2× or more for high gain). Defaults near unity loudness; Level knob manages the boost | Alias check at high gain (a 3–5 kHz sine shouldn't produce tones below it); gain at Level max matches the spec (e.g. "+12 dB"); default loudness within ±3 dB of bypass, measured as average (RMS) level on a guitar-level signal, not peaks |
| **Level-sensitive** (behaviour depends on input level) | drive, compressor, gate, envelope filter, auto-wah, sag | Tune for the real source: guitar/bass peak around −20 dBFS into a MOD; synths and line sources are much hotter. Ask which in the kick-off | Tests at the source's real level, not a hot test signal |
| **Modulated delay** (an LFO moves a delay tap) | chorus, flanger, vibrato, tape wow | Interpolated reads (Hermite for audible taps); pitch deviation scaled by delay time | Pitch wobble in cents (`warble_cents`) |
| **Stereo** | reverb, ping-pong, chorus, auto-pan | Opposite-polarity outputs cancel in mono; say so | Decorrelation; mono sum still sounds right |
| **Has a Mix knob** | most time-based effects | Dry at unity in bypass whatever Mix says | Bypass at Mix 100 |
| **Instrument / MIDI** (no audio input) | synth, drum voice | Not yet covered by this playbook. MOD's bypass silences these rather than passing audio. Say so, and harvest what you learn (`harvesting.md`) | — |

## 3. Stripping the template

`templates/plugin/` is an echo, so it carries most traits. Its source and tests mark each part with the trait it serves (`[tail]`, `[feedback]`, `[buffer]`, `[mix]`). Keep the `[every]` parts; delete the parts for traits the plugin doesn't have, with their ports and tests.

A clean boost, for example, keeps: real-time structure, first-run snap, smoothing, bypass crossfade, the timing/level/bypass/torture/silence tests. It drops: the buffer, feedback, Tails, the wet limiter and their tests, and adds the nonlinear/gain rules and tests.

Say in the spec which parts were dropped and why, so a later change ("add a delay to the fuzz") knows to bring them back.
