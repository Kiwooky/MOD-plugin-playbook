# Hardware feedback: from "it sounds wrong" to a fix

Tests prove behaviour; only playing proves it's musical. Every upload ends with the human playing it and telling the agent what they heard.

## Collect a usable report (`templates/hardware-report.md`)

- **Version installed** (a stale build is the first suspect: see versioning).
- **The settings** when it happened (every knob that isn't at default).
- **What they heard,** in their words, and roughly how often.
- **Their source:** guitar or synth, how hard they play, what's before and after the plugin.
- **The MOD OS version.**

If the report doesn't say which version or settings, **ask before changing anything.** Guessing produces fixes for the wrong problem.

## Turn it into a test that fails first

1. **Reproduce offline** at their settings, with musical input at their level.
2. **Find the cause, not just the symptom.** The oil-can delay's "digital ticks" were two separate causes: the output going over 0 dBFS (converter clipping), and saturator edges aliasing in short-time runaways. One fix would have left half the problem.
3. **Write the failing test,** then fix until it passes, then run the whole gate.
4. **Check the test can fail:** a test that passes on the broken build proves nothing.

## When the request is a design change

"Make it oscillate easier", "more extreme", "duller": discuss the options with numbers, recommend one, then build. Map the behaviour (a grid, a sweep) before and after, so the change lands where the human expects.

## Feedback from an oil-can delay test cycle (examples)

| Report | Real cause | Fix |
| --- | --- | --- |
| "Turned hiss and hum off after 5 seconds" | Feature not wanted | Removed; kept the movement as a new control |
| "Sag a bit too subtle" | Tuned for hot signals | Full effect at about −20 dBFS |
| "Digital ticks here and there" | Output over 0 dBFS + aliasing in loops | Output soft knee, 2× oversampled saturators, loop roll-off |
| "Repeat and Reverb seem to do the same thing" | Both made clean repeats at near-equal spacing | Reverb became a diffused wash |
| "It will not oscillate any more" | Runaway edge moved to a 7% sliver of the knob | Edge mapped on a grid and moved to 8–10, Reverb can tip it |
| "Hold should be latching" | Momentary-by-default property | Removed it |
