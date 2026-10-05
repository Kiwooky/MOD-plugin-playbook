# DSP for MOD

MOD units are small ARM computers. The Duo (Cortex-A7, 32-bit) is the tightest; design for it and the Duo X / Dwarf follow.

## Real-time basics

- **`run()` is real-time:** no allocation, I/O, locks or printf. Allocate everything in the constructor, sized for **96 kHz**, and clear it in `activate()`. Power-of-two buffers with a mask.
- **Controls arrive with the first `run()`,** not before `activate()`. Snap every smoother to its target on the first run, then smooth.
- **Smooth anything that moves a gain, a filter or a delay tap** (one-pole, about 10 ms for gains, longer for delay times, which glide like tape).
- **Land smoothers on their target.** In float, `g += c * (target - g)` stalls once the step is below float resolution: EC-280's "dry at unity" measured 1 + 3e-5 with a 10 ms smoother. Snap to the target at the end of the block once within about 1e-4 (in tests).
- **Scale every time constant and delay length by the sample rate.** Test at 44.1, 48 and 96 kHz.
- **Denormals:** add a tiny constant (1e-18) in every feedback path.

## CPU

- **No per-sample `pow`, `exp`, `log`, `sin`, `tanh`.** Use a rational tanh (`x(27+x²)/(27+9x²)`, flat beyond ±3), a parabolic sine for LFOs, tables for anything periodic.
- **Control rate:** recompute coefficients every 16 samples, smoothing in between. Retune filters only while a control moves.
- **Divisions cost** on the Duo (~14+ cycles). Hoist `1/x` to control rate where you can.
- **Measure, don't guess.** `tools/bench.py` renders the same audio through several plugins and prints relative cost; run it on the Duo build under qemu for Duo-like ratios. Only the Duo's own CPU meter gives absolute load. Can-Abyss's first estimate was wrong in both directions.

## Saturation and feedback loops

- **Oversample nonlinearities inside loops.** A saturator in a feedback loop re-sharpens its own edges every lap, and without oversampling the edges alias into audible "digital" ticks. Even cheap 2× (midpoint interpolation, nonlinearity at both points, 2-tap average) fixed it in Can-Abyss.
- **Cap the loop bandwidth.** Short delays with high feedback put many laps per second through the saturator; a gentle roll-off in the feedback path (about 6 kHz) keeps runaway edges from building.
- **Map where it runs away, on a grid.** When two controls feed the same loop (feedback + a second recirculation), their gains add. Chart a grid of knob values against "decays / runs away" before the human tries it, and tune until the edge sits where it is playable (several knob positions wide, not a sliver).
- **A noise floor in a loop makes any loop gain above 1 self-start, at any frequency.** Hiss (or a denormal guard, or any input) seeds the loop, so an in-loop filter peak a little above unity runs away with no input at all. EC-280 at Duration 7.7 ran away from its own hiss even though its DC loop gain was under 1. A compressive clip can't make "soft playing stays stable, hard playing tips it over": that needs an element whose gain rises with level (in tests).
- **A "Safety" output limiter** (lookahead 2 ms, soft knee, wet output only) lets runaways stay wild inside the loop while the output stays under a set ceiling.

## Outputs

- **Soft-knee every output just under 0 dBFS, always.** Anything past 0 dBFS hard-clips at the converter. That was the "digital ticks" in Can-Abyss 1.0.2.
- **Opposite-polarity outputs:** a classic stereo trick (dry + wet on one side, dry − wet on the other) is wide in stereo but cancels the wet if both outputs end up in one mono input. Say so in the README, and recommend one output for mono rigs.
- **Level:** guitars into a MOD peak around −20 dBFS (the nominal input level isn't documented; this is from testing). Tune dynamics (compressors, sag, saturation thresholds) for that, not for a hot test signal.

## Delays and modulation

- **A modulated delay tap bends pitch by the rate the delay changes.** A fixed percentage of delay time gives far more pitch wobble on long delays than short ones. Scale speed-type modulation by current speed so the pitch deviation stays constant across delay times (Can-Abyss: from 20 cents of seasick wobble to a steady 4.5 at any time).
- **Varispeed:** let the read point follow an integrated motor speed with inertia (a one-pole on speed), and the pitch bends like tape. A fixed-cell "disc" model costs far more at short times than a tape-style delay line.
- **Hermite (4-point) interpolation** for audible taps; linear is fine for internal taps that are filtered anyway.

## Clocked delays (BBD, early digital)

Some originals don't move a tap: they change the clock that walks a fixed-length memory (bucket brigades, 1980s sampler-style delays). Then delay = length ÷ clock, sweeps bend pitch for free, and a frozen buffer varispeeds when the clock changes. Model it that way:

- A fixed buffer read and written at a **virtual clock**. Per host sample, count the ticks that fall inside it; interpolate the input at each tick's exact time, and **integrate the zero-order-hold output over the host sample** (a box filter) so a clock faster than the host rate decimates cleanly.
- Keep the original's fixed anti-alias and reconstruction filters at the host rate. When the clock runs slow, a little aliasing gets through, as on the hardware.
- MultiPlay: 8-bit memory, 13:1 clock sweep, delays within 2 % at 44.1, 48 and 96 kHz, up to about 12 ticks per host sample, about 0.4 % of one x86 core at its fastest clock.

## Resistor mixing networks

Switch matrices and mixers on old gear often join several taps through resistors onto one node. Model the node as a passive bus, not a sum: V = Σ(Gᵢ·Vᵢ) ÷ (ΣGᵢ + G_load), with G = 1/R and G_load the next stage's input. Engaging more sources then gets fuller but less than additive, as on the hardware; plain summing made EC-280's button combinations far too loud. Normalise one reference setting to unity and let the rest follow (in tests).

## Companders (NE570 and similar)

Put the compressor's level detector on its **output** and the expander's on its **input**. Then the expander sees the same envelope the compressor applied and the pair cancels, even during attacks, apart from what happened in between (quantisation, clipping). Sensing the compressor's input instead overshot every attack by about 16 dB in MultiPlay's first model.

## Noise

- **Noise as a modulation source** (some "chorus" circuits are a noise diode, not an LFO): white noise → one-pole low-pass, scaled by √(2/a) (a = the filter coefficient) for unit variance, then a soft clip and a one-pole high-pass. It gives a band-limited random drift whose level doesn't depend on the sample rate. EC-280: 1.6 Hz low-pass and 0.5 Hz high-pass from the schematic, added to the BBD clock (in tests).
- **Modelled hiss and hum are rarely wanted.** In Can-Abyss's first hardware test, hiss and hum were switched off within seconds. Players kept the *movement* (warble, wear) and dropped the dirt. Build clean; add character through movement and saturation.
