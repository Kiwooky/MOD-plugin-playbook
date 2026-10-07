# LV2 and MOD rules

What MOD's hosts expect, including the parts nobody documents. Verified on a MOD Duo (MOD OS 1.13/1.14) with DPF at `61d38eb6…`.

## TTL: hand-written, checked against DPF

DPF's `lv2_ttl_generator` can't run on the ARM cross-build, so the TTL is written by hand. `tools/check.sh` builds natively, runs the generator and compares (`tools/ttlcmp.py`). Expected differences are only audio port names/symbols and `mod:preferMomentaryOnByDefault`.

- **Port order:** audio inputs, audio outputs, then controls in enum order; indices sequential from 0. `kParameterCount` equals the number of control ports.
- **Counts match** across `DISTRHO_PLUGIN_NUM_INPUTS/OUTPUTS`, the TTL and `run()`.
- **The URI** is identical in `DISTRHO_PLUGIN_URI`, `manifest.ttl`, `<name>.ttl` and `modgui.ttl`.
- **The binary** in `manifest.ttl` is `<name>_dsp.so`, where `NAME` in the plugin Makefile = `<name>`.
- **Required features:** DPF needs `opts:options` and `urid:map`. Declare them or strict hosts refuse the plugin (the cookbook's examples omit these; they work only because mod-host always supplies both):

```turtle
lv2:optionalFeature lv2:hardRTCapable ;
lv2:requiredFeature <http://lv2plug.in/ns/ext/options#options> ,
                    <http://lv2plug.in/ns/ext/urid#map> ;
lv2:extensionData <http://lv2plug.in/ns/ext/options#interface> ;
```

- **Logarithmic knobs** (`pprops:logarithmic` + DPF `kParameterIsLogarithmic`) for time and frequency. mod-ui maps their position on a log scale.
- **Enumerations** (`lv2:enumeration` + `lv2:scalePoint`, DPF `enumValues`) for switches with labelled positions.

## Bypass in the plugin

Without a bypass port, mod-host bypasses by copying the input straight to the output from the next audio block: an instant switch, no crossfade (mod-host `effects.c`, source-checked). On a processed signal (a driven fuzz, a wet delay) that's a step in the waveform, heard as a pop. If the plugin has an `lv2:designation lv2:enabled` port, mod-host does **not** hard-bypass. It sets the port (1 = active) and keeps calling `run()` (mod-host `effects.c`, mod-ui `host.py`), so the plugin can fade.

Every plugin gets this: the player hears a standard bypass (effect out, dry through at unity), just without the click. Tails are a separate, optional extra for effects that have one.

- **DPF:** `p.initDesignation(kParameterDesignationBypass)`, last in the enum. DPF inverts the value internally (1 = bypassed).
- **TTL:** symbol `lv2_enabled`, name "Enabled", default 1, `lv2:integer , lv2:toggled`, `lv2:designation lv2:enabled`.
- **Pattern (every plugin):** smoothed gains (about 10 ms) between the processed signal and the dry. **Effects with a tail** add the Tails option: smoothed input, wet and dry gains. **Tails on:** bypass mutes only the effect's input; dry goes to unity; the tail rings out. **Tails off:** wet fades, then the state is cleared once (in slices if it's big, not one huge memset in one block).
- **With a Mix knob: dry at unity in bypass, whatever Mix says.** Fade the dry gain to 1 alongside the wet fade (`dry = 1 + wetGain × (mixDry − 1)`). The digital delay forgot this and went silent in bypass at full wet.
- **Recreations: copy the original's bypass instead.** Some hardware just mutes the wet while the effect keeps running (the digital delay: a held loop carries on and is there again when you switch back on). Ask the owner; then a Tails switch may not belong at all.

## Versioning (the "tuna can" lesson)

Two jobs, one number. On every path it's a **cache-buster**; on path B it's also a **release number**.

- **MOD caches plugin info and images, keyed by URI + version.** Re-uploading with the same version shows stale data. A face-less first install leaves the default "tuna can" thumbnail cached in the browser until 2035. This bites hardest on path A, where the same `.mk` is uploaded again and again.
- **Path A: bump `lv2:microVersion` on every upload, automatically.** The person never has to think about it; mention the new number when you hand over the file so they can check what's installed.
- **Path B: real releases.** Bump micro for fixes, minor for new behaviour; tag releases, keep the CHANGELOG.
- Keep `lv2:minorVersion` even and ≥ 2 (0 = pre-release, odd = unstable by LV2 convention).
- **Keep DPF's `d_version()` in step:** major > 0 → minorVersion = minor + 2, microVersion = micro. `d_version(1,0,3)` ↔ minor 2, micro 3.
- **Ship a face from the first upload.**
- **Stale-cache check:** hard-refresh the MOD UI (Cmd/Ctrl+Shift+R), or open `http://192.168.51.1/effect/get?uri=<uri>&nocache=1`.

## Ports are forever (once shared)

Saved pedalboards store port symbols and values. After anyone else has the plugin, never remove, reorder or rename ports or change the URI. Before that, change freely, but tell the tester to re-add the plugin to their pedalboard.

## Factory presets

Ship presets inside the bundle: `presets.ttl` holding `pset:Preset` resources (`lv2:appliesTo <plugin URI>`, `rdfs:label`, `lv2:port [ lv2:symbol … ; pset:value … ]`), each also listed in `manifest.ttl` with `rdfs:seeAlso <presets.ttl>`. Leave out the bypass port and footswitch states. From presets someone made on a unit: `docs/presets.md`.

## Footswitches and gestures

- **Path:** footswitch → front panel → mod-ui → mod-host → control port, applied at the next audio block (never audio-rate).
- **Toggle mode** reports presses only. **Momentary mode** reports press and release (MOD OS ≥ 1.10).
- **Latching is the default.** Add `mod:preferMomentaryOnByDefault` (alongside `lv2:toggled`) only when the person asks for momentary. The user can still choose per assignment in the addressing dialog, and that choice is stored with the assignment: re-assign after changing the default.
- **Multi-gesture lag:** one press can't be confirmed until the double-press window expires. Act on press-down immediately and make the other gestures corrections (undo on hold, reset on double press).

## Brand and maker

Change `DISTRHO_PLUGIN_BRAND`, `getMaker()`, `foaf:name` and `modgui:brand` together. Where it shows: printed on stock faces (big, in boxy's brand box), and as the second line under the plugin's name in MOD's plugin list (truncated to about 17 characters). Use the person's name or alias, or "MOD Cookbook"; never invent one.
