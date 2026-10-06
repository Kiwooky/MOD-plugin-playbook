# <Plugin name>: spec v0.1

<date> · <author>

## Setup (from the kick-off in AGENTS.md)

| Question | Answer |
| --- | --- |
| Shipping path | A (single .mk) / B (GitHub repo) |
| Agent can run commands? | yes / no (chat-only: list the checks not run) |
| MOD units | Duo / Duo X / Dwarf |
| Starting point | imagined / reference sound / specific gear (`docs/effect-profile.md`) |
| Traits | every + tail / feedback / buffer / nonlinear-gain / level-sensitive / modulated delay / stereo / Mix knob |
| Source plugged in | guitar / bass / synth or line level |
| Face | stock (style, colour, extra footswitches) / placeholder / own artwork |
| Name, maker, URI | … / … / `urn:mod-cookbook:<name>` or `https://github.com/<owner>/<repo>` |

## Concept

One paragraph: what it is and what makes it sound like itself. For recreations, how the original works.

## Sources and provenance

| Feature | Basis | Reference |
| --- | --- | --- |
| … | documented / measured / commercial model / owner wish / our idea / guess | link or note |

## Signal flow

A short description or diagram (Mermaid renders on GitHub).

## Ports

Audio first, then controls in enum order; the bypass port last. Frozen once shared.

| # | Symbol | Name | Range | Default | Notes |
| --- | --- | --- | --- | --- | --- |
| 0 | `in` | In | audio | | |
| … | | | | | |
| n | `lv2_enabled` | Enabled | bypass | 1 | `lv2:designation lv2:enabled`, last |

## Mappings

Every row says *guess* until it is measured, then gives the measurement.

| Control | Mapping | Notes |
| --- | --- | --- |
| … | … | guess / measured: … |

## CPU and memory

Measured relative cost (`tools/bench.py`), buffers allocated, what was done to keep it lean.

## Test plan

- [ ] Every plugin: timing at 44.1/48/96 kHz, levels, click-free bypass at unity, torture, no ticks, silence
- [ ] Per trait (`docs/effect-profile.md`): e.g. tails on/off, under 0 dBFS at max feedback, no aliasing at full gain
- [ ] Template parts dropped, and why
- [ ] One line per promise above
- [ ] One line per hardware report

## Face notes

Controls on the face, assets needed, layout.

## Open questions and parked ideas
