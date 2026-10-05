# Testing

One command: `tools/check.sh` (see `AGENTS.md`). This page explains what it runs and what your plugin's tests should cover.

## The rig

| Step | Tool | Why |
| --- | --- | --- |
| Build native, Duo (arm32), Duo X/Dwarf (arm64) | `tools/harness.mk` runs the recipe's own Buildroot hooks without Buildroot | Same commands the builder runs; warnings fail |
| TTL vs DPF | `lv2_ttl_generator` + `tools/ttlcmp.py` | The hand-written TTL must match the code |
| Load check | `lv2info` | The bundle parses and the URI resolves |
| Audio tests, native | `tools/lv2host.c` + your test script (`tools/lv2test.py`) | DPF plugins won't load in `lv2apply`; this offline host does, with control changes at chosen samples (`@sample:port=value`) |
| Same tests on the Duo build | qemu-arm | Catches ARM-only problems; results must match native |
| CPU | `tools/bench.py` | Relative cost vs plugins you know; absolute only on the device |

Packages: `g++ g++-arm-linux-gnueabihf g++-aarch64-linux-gnu qemu-user lilv-utils git make` and Python `numpy scipy rdflib` (plus `pillow playwright` for faces).

## What every plugin should test

Copy `templates/plugin/tests/test_simple_echo.py` and keep these:

- **Timing / tuning** at 44.1, 48 and 96 kHz (the first echo lands on the Time setting, a filter's corner is where it should be, …).
- **Levels:** about unity where the spec says so.
- **Bypass** with Tails on and off: dry at exactly unity, no step bigger than the signal's own.
- **Torture:** every knob at its extreme, hot input, three sample rates: finite and bounded.
- **No ticks** with musical input (`pluck_train` + `tick_count`), **outputs under 0 dBFS**.
- **Silence in, silence out** (unless noise is a feature).

Then **one test per promise in the spec** ("Wobble 10 is about 4× stock", "Repeat 7 + Reverb 10 runs away, Repeat 6 never does"), and **one per hardware report**.

## Rules for writing tests

- **Test at guitar level** (`pluck_train` peaks around −16 dBFS). Can-Abyss's Sag was tuned on hot test signals and barely reacted to a real guitar.
- **Smooth envelopes on test signals.** Abrupt starts and stops are clicks; the first tick hunt in Can-Abyss found the test signal's own edges.
- **Validate a detector before trusting it:** clean input must read 0, planted faults must be found. `tick_count` measures the *treble share* (clicks are almost all treble; bright notes are not), and was checked against planted clicks down to −46 dBFS, white noise, and clean plucks.
- **Test the knob's shape, not only its ends.** "Runs away at 10" passed while the real edge sat at 9.3, a sliver of the knob nobody could find. Test both sides of an edge at playable positions.
- **Leave margin** in thresholds so native and ARM floating point don't flip a result.
- **Make the gate fail on purpose once** (a wrong TTL default, an unused variable) to prove it can.

## The library (`tools/lv2test.py`)

`Plugin(order, defaults, n_in, n_out).run(x, sr, events, **controls)`, `check(name, ok, info)`, `done()`, and helpers: `db`, `rms`, `centroid` (brightness), `pluck_train`, `tick_count`, `warble_cents` (pitch wobble of a steady sine), `max_step` (clicks).
