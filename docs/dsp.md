# DSP for MOD

MOD units are small ARM computers. The Duo (Cortex-A7, 32-bit) is the tightest; design for it and the Duo X / Dwarf follow.

## Real-time basics

- **`run()` is real-time:** no allocation, I/O, locks or printf. Allocate everything in the constructor, sized for **96 kHz**, and clear it in `activate()`. Power-of-two buffers with a mask.
- **Controls arrive with the first `run()`,** not before `activate()`. Snap every smoother to its target on the first run, then smooth.
- **Smooth anything that moves a gain, a filter or a delay tap** (one-pole, about 10 ms for gains, longer for delay times, which glide like tape).
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
- **A "Safety" output limiter** (lookahead 2 ms, soft knee, wet output only) lets runaways stay wild inside the loop while the output stays under a set ceiling.

## Outputs

- **Soft-knee every output just under 0 dBFS, always.** Anything past 0 dBFS hard-clips at the converter. That was the "digital ticks" in Can-Abyss 1.0.2.
- **Level:** guitars into a MOD peak around −20 dBFS (the nominal input level isn't documented; this is from testing). Tune dynamics (compressors, sag, saturation thresholds) for that, not for a hot test signal.

## Delays and modulation

- **A modulated delay tap bends pitch by the rate the delay changes.** A fixed percentage of delay time gives far more pitch wobble on long delays than short ones. Scale speed-type modulation by current speed so the pitch deviation stays constant across delay times (Can-Abyss: from 20 cents of seasick wobble to a steady 4.5 at any time).
- **Varispeed:** let the read point follow an integrated motor speed with inertia (a one-pole on speed), and the pitch bends like tape. A fixed-cell "disc" model costs far more at short times than a tape-style delay line.
- **Hermite (4-point) interpolation** for audible taps; linear is fine for internal taps that are filtered anyway.

## Noise

- **Modelled hiss and hum are rarely wanted.** In Can-Abyss's first hardware test, hiss and hum were switched off within seconds. Players kept the *movement* (warble, wear) and dropped the dirt. Build clean; add character through movement and saturation.
