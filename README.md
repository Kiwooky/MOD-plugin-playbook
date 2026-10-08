# MOD Plugin Playbook

**Build MOD Duo / Duo X / Dwarf plugins with an AI agent, and get them right on the device, not just in the chat.**

The [MOD plugin cookbook](https://github.com/mod-audio/mod-plugin-cookbook) shows how to describe a plugin and get a single `.mk` file for the MOD Online Builder. This playbook is what came after: the process, tools and hard-won rules from building several plugins that shipped to real hardware.

It works with **any AI that can fetch a link**, from a plain chat to a coding agent (Claude Code, Codex CLI, Cursor, Gemini CLI). Nothing in it depends on one AI vendor.

## Start with one link

Open a chat with your AI and send it this:

> Read https://github.com/Kiwooky/MOD-plugin-playbook/blob/main/AGENTS.md?v=0.5.0 and help me build a plugin for my MOD.

It reads the cookbook and the playbook, asks what you'd like to build, proposes the knobs, and hands you a `.mk` file. Upload that at [builder.mod.audio/buildroot](https://builder.mod.audio/buildroot) with your MOD connected over USB, then play it and tell the AI what you heard.

An AI that can run commands also builds and tests the plugin before you upload it. In a plain chat it writes the file and tells you which checks it couldn't run.

**If your AI can't open the link** (some free chat plans can't read GitHub files): open [`ALL-IN-ONE.md`](ALL-IN-ONE.md), click the download button (↓), attach the file to your chat and describe your plugin. It's the whole guide in one file.

## What you get

- **A one-link start** (`AGENTS.md`): the agent reads the cookbook as required reading, asks about your idea, and proposes the plugin's shape for you to confirm. It ships as:
  - **A. A single `.mk`** for builder.mod.audio: no GitHub, one file to upload. The default.
  - **B. A GitHub repo** with a package `.mk` that builds from a commit, for sharing source and store releases. Offered when you want it.
- **A tested template plugin** (`templates/plugin/`) that builds both ways: sources in normal folders, assembled into a single `.mk` or built as a repo.
- **One-command checks** (`tools/check.sh`): native + Duo + Duo X/Dwarf builds through the builder's own steps, the hand-written TTL compared with DPF's generator, a load check, and audio tests run natively and on the Duo build under emulation. Compiler warnings fail it.
- **Pedal faces from the first upload:** MOD SDK stock pedals (`tools/stock_face.py`: compact stompbox, Hammond-style box, British box or tin can, sized from the knobs and footswitches), or a placeholder drawn from the TTL (`tools/placeholder_face.py`).
- **Face click tests** (`tools/face_click_test.py`): every control pressed with mod-ui's own widget code (mouse, wobble and touch), including controls drawn by a face script, so a face that drops clicks fails before it reaches a unit.
- **Factory presets from a unit** (`tools/presets_from_device.py`): presets made on the MOD become presets that ship with the plugin.
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

Then point your agent at `AGENTS.md` and describe the plugin you want. (That's the developer route; most people only need the one link above.)


## What the human still does

The agent can't upload to the builder, push to GitHub with your account, or hear the result. You install each build on your MOD, play it, and report back (`templates/hardware-report.md`). That loop is where the plugin gets good.

## Contributing

Lessons from your own builds are welcome: see `docs/harvesting.md`. Keep claims honest: "verified on a Duo", "in tests", or "believed".

## Licence

GPL-3.0-or-later (`LICENSE`). Copyright (c) 2026 New Horizon Electronics and contributors.

This covers the template plugin too, so plugins built from it are GPL-3.0-or-later. The recipe format and parts of the template follow MOD's [plugin cookbook](https://github.com/mod-audio/mod-plugin-cookbook), MIT, Copyright (c) 2026 MOD Audio Limited (`LICENSES/MIT-mod-plugin-cookbook.txt`). DPF (fetched by the tools, or a submodule in path B repos) is ISC. The MOD SDK stock pedal art that `tools/stock_face.py` fetches is GPL-3.0.
