# Harvesting lessons from other sessions

This playbook started from Taj Mahal's handover and the Can-Abyss build. MultiPlay 20/20 was harvested in 0.2.0. Other plugin sessions (EC-280, and yours) will have learned things that belong here.

## What to look for

- **Rules that cost a round trip:** a build or upload that failed, a behaviour on the device that tests didn't catch, a MOD quirk.
- **Patterns that worked:** a DSP technique, a test, a face trick, a way of asking the human.
- **Tools** that would help every plugin (generalise them; don't paste plugin-specific scripts).
- **Corrections:** anything here that turned out wrong.

## A prompt to paste into an old session

> I'm building a shared MOD plugin playbook for the community (any LLM agent should be able to use it). Look back over this whole session and list everything we learned that would help someone building a different plugin: build/upload problems and their fixes, MOD/mod-ui quirks, DSP patterns, test techniques, face (modgui) techniques, and ways of working that saved time. For each item give: the rule in one line, what happened that taught it, and whether it's verified (on hardware / in tests) or only believed. Leave out things specific to this one plugin's sound. Also flag anything we did that turned out to be a mistake.

## How to add it

- Rules with their incident → `docs/lessons.md`, plus the topic doc they belong to (`dsp.md`, `testing.md`, …).
- New tools → `tools/`, generic, with a docstring, and a line in `testing.md` or the doc that uses them.
- Keep claims honest: say "verified on a Duo", "in tests" or "believed".
