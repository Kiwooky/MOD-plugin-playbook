# MOD Plugin Playbook

**Build MOD Duo / Duo X / Dwarf plugins with an AI agent, and get them right on the device, not just in the chat.**

The [MOD plugin cookbook](https://github.com/mod-audio/mod-plugin-cookbook) shows how to describe a plugin and get a single `.mk` file for the MOD Online Builder. This playbook is what came after: the process, tools and hard-won rules from building several plugins that shipped to real hardware (Taj Mahal, MultiPlay 20/20, Can-Abyss Delay and others).

It works with **any coding agent** (Claude Code, Codex CLI, Cursor, Gemini CLI, or a chat with a code sandbox). Nothing in it depends on one AI vendor.

## What you get

- **A setup interview** (`AGENTS.md`) so the agent asks the right questions first, including how you want to ship:
  - **A. A single `.mk`** for builder.mod.audio: no GitHub, one file to upload. Most people start here.
  - **B. A GitHub repo** with a package `.mk` that builds from a commit, for sharing source and store releases.
- **A tested template plugin** (`templates/plugin/`) that builds both ways: sources in normal folders, assembled into a single `.mk` or built as a repo.
- **One-command checks** (`tools/check.sh`): native + Duo + Duo X/Dwarf builds through the builder's own steps, the hand-written TTL compared with DPF's generator, a load check, and audio tests run natively and on the Duo build under emulation. Compiler warnings fail it.
- **Instant placeholder faces** (`tools/placeholder_face.py`) drawn from the TTL, so every plugin ships with a face from its first upload.
- **A test library** (`tools/lv2test.py`): an offline host runner plus helpers for levels, brightness, pitch wobble, clicks and a validated tick detector.
- **The rules** (`docs/`), each with the incident that taught it.

## Quick start

```sh
git clone <this repo> && cd mod-plugin-playbook
sudo apt-get install g++ g++-arm-linux-gnueabihf g++-aarch64-linux-gnu qemu-user lilv-utils
pip install numpy scipy rdflib            # + pillow playwright for face screenshots
cd templates/plugin
../../tools/check.sh --src plugins/simple-echo --bundle bundle/simple-echo.lv2 --test tests/test_simple_echo.py
# -> dist/simple-echo.mk: upload at https://builder.mod.audio/buildroot with your MOD connected
```

Then point your agent at `AGENTS.md` and describe the plugin you want.

## What the human still does

The agent can't upload to the builder, push to GitHub with your account, or hear the result. You install each build on your MOD, play it, and report back (`templates/hardware-report.md`). That loop is where the plugin gets good.

## Contributing

Lessons from your own builds are welcome: see `docs/harvesting.md`. Keep claims honest: "verified on a Duo", "in tests", or "believed".

## Licence

MIT. DPF (fetched or vendored by the tools) is ISC.
