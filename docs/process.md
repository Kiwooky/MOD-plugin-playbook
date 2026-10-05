# Process: from idea to release

The same stages for both paths. Each ends with something checkable. Skipping one is how the bugs in `lessons.md` happened.

| # | Stage | Done when |
| --- | --- | --- |
| 0 | **Setup interview** (`AGENTS.md` §0) | Path, tools, units, face, identity recorded in the spec |
| 1 | **Concept** | One paragraph on what it is and why it sounds like itself. For recreations: how the original works, with sources |
| 2 | **Spec** (`templates/spec-template.md`) | Controls with ranges and defaults; every mapping marked *guess* or *measured*; a sources table |
| 3 | **Ports** | The port table is settled; it can still change until the first public share, then never again |
| 4 | **DSP** (`dsp.md`) | Builds clean on three targets |
| 5 | **Tests** (`testing.md`) | Generic checks plus one per promise in the spec; all pass natively and on the Duo build under qemu |
| 6 | **Face** (`modgui.md`) | Placeholder or real; screenshot and thumbnail rendered; ships with the first upload |
| 7 | **Upload + play** | The human installs it and plays it; the agent asks what they heard (`hardware-feedback.md`) |
| 8 | **Iterate** | Each report → failing test → fix → version bump → upload |
| 9 | **Release** | Path B: release checklist, frozen ports, licence, manual, presets, store steps |

## Working with the human

- **Discuss before building** when a request changes the design (ports, what a knob means). Build straight away when it's a fix inside the agreed design.
- **Ask one question at a time,** with a recommendation.
- **Report numbers, not adjectives:** "peaks at −2.4 dBFS", "4.5 cents RMS", "1.2× Taj Mahal's CPU".
- **Say what wasn't verified.** No test can tell you whether it's musical; ask.
- **Run dependent steps in order.** Render the face after rebuilding the bundle; save or upload a file after the edit that changes it has finished, not in parallel with it.
- **Tell people where files land** and give exact clicks or commands for their tools (GitHub Desktop, Finder, Terminal).
- **Keep the docs honest as you go:** spec, CHANGELOG and README change in the same step as the code.
