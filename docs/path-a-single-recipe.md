# Path A: a single `.mk` for the MOD Online Builder

One file, no GitHub. You upload it at builder.mod.audio with your MOD connected over USB, and it installs. This is the MOD plugin cookbook's model (github.com/mod-audio/mod-plugin-cookbook), with the gaps filled in.

## How to work

Keep the sources as normal files (`plugins/<name>/`, `bundle/<name>.lv2/`), not inside the `.mk`. Editing C++ inside a `define` block is how `$` bugs and drift between code and TTL happen. `tools/assemble_recipe.py` writes the `.mk` for you, and `tools/check.sh` does it as part of the gate:

```sh
cp -r templates/plugin my-plugin && cd my-plugin        # then rename (below)
../tools/check.sh --src plugins/<name> --bundle bundle/<name>.lv2 --test tests/test_<name>.py
# -> dist/<name>.mk, ready to upload
```

Renaming the template: the folder names, `NAME` in the plugin Makefile, the class and file names, `DISTRHO_PLUGIN_NAME/URI/BRAND`, `getUniqueId()`, and the URI in both TTL files. The URI convention for path A is `urn:mod-cookbook:<name>`.

## Uploading

1. Connect the MOD over USB; its web UI opens (usually 192.168.51.1).
2. Open https://builder.mod.audio/buildroot in Chrome and upload `dist/<name>.mk`.
3. **The filename must match the variable prefix** (`simple-echo.mk` ↔ `SIMPLE_ECHO_`); the builder rewrites the prefix internally. The assembler enforces this.
4. Wait for the build (the first one takes a few minutes), then click **Install**.
5. **Bump the version before every re-upload** (`docs/lv2-and-mod-rules.md`), or MOD shows stale data.

## Anatomy of the generated recipe

- `<P>_VERSION / _SITE / _SITE_METHOD = git`: DPF at the pinned commit `61d38eb6…`.
- **Sources** (C++, header, Makefile): `define` blocks, `export`ed, written with `printf '%s\n' "$$VAR"` in CONFIGURE into `$(@D)/examples/<name>/` (the cookbook pattern; proven on the builder).
- **BUILD:** `$(TARGET_MAKE_ENV) $(TARGET_CONFIGURE_OPTS) $(MAKE) NOOPT=true -C $(@D)/examples/<name> lv2_dsp`.
- **INSTALL:** copies `<name>_dsp.so`, then writes every bundle file (TTLs, face HTML/CSS/JS, images) with make's `$(file >path,$(VAR))`, decoding images from base64.
- The last line: `$(eval $(generic-package))`.

## Rules the assembler handles for you (and why)

- **Over ~100 KB, `export` breaks.** Linux refuses any single environment variable over 128 KB ("Argument list too long"). Big sources and all bundle files use `$(file)` instead.
- **`$(file)` runs when make expands the step,** before its shell commands, so it writes into a directory that already exists (`$(@D)`), then `cp`/`base64 -d` move things into place.
- **A literal `$` in embedded text must be `$$`.** The assembler escapes automatically.
- **The plugin Makefile's include path changes:** `../../dpf/Makefile.plugins.mk` in a repo becomes `../../Makefile.plugins.mk` inside DPF's `examples/` on the builder. The assembler rewrites it.

## Size budget

A face adds roughly 200–300 KB (background JPEG, knob strip as a 256-colour PNG, screenshot, thumbnail). Full-colour PNGs are about 4× bigger. Taj Mahal's recipe with face was ~292 KB and built fine.

## Moving to path B later

Everything in `plugins/` and `bundle/` carries over unchanged. Add the top-level `Makefile`, the package file, and `dpf/` (`tools/vendor_dpf.sh`). See `docs/path-b-github-repo.md`. If the plugin was shared under `urn:mod-cookbook:<name>`, decide deliberately whether to keep that URI (pedalboards keep working) or start a new identity.
