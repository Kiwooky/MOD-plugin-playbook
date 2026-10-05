# Pedal faces (modgui)

**References:** the MOD Wiki page "Preparing the Bundle", `mod-audio/mod-sdk` (the `modgui.ttl` spec, stock templates in `html/resources/templates`) and `mod-audio/mod-ui` `html/js/modgui.js`. The mod-ui source is the ground truth.

## Files

- `modgui.ttl`, linked from `manifest.ttl` with `rdfs:seeAlso <modgui.ttl>`: `modgui:gui [ resourcesDirectory, iconTemplate, stylesheet, (javascript), screenshot, thumbnail, brand, label, port list ]`.
- `modgui/`: the HTML template, CSS, optional script, images.

## Template (Mustache)

- Root: `class="mod-pedal <yourclass>{{{cns}}}"` plus an element with `mod-role="drag-handle"`.
- Knobs: `mod-role="input-control-port" mod-port-symbol="<symbol>"` (the default *film* widget).
- **Buttons and toggles: add `mod-widget="switch"`.** The film widget ignores a click if the mouse moves a couple of pixels, which feels broken. The switch widget sets class `on`/`off`.
- Bypass: `mod-role="bypass"`. Its classes are inverted: `on` = **bypassed**, `off` = active.
- **Multi-position switches (enumerations):** a film works, but a click only steps to the next position and wraps, whatever part of it you click. To let people click the position they want, lay transparent click zones (plain divs, no `mod-role`, higher `z-index`) over each position and have the face script call `funcs.set_port_value('<symbol>', value)` on click. The film still draws the switch. (MultiPlay's range lever.)
- Audio jacks: copy the `{{#effect.ports.audio.input}}…` blocks from a stock template.

## CSS

Prefix every selector with `.yourclass{{{cns}}}`; load images as `url(/resources/<file>{{{ns}}})`.

**Filmstrips** (one horizontal row, frame 0 = minimum):
- frames = strip width ÷ **element width** (frames needn't be square)
- frame shown = round((value − min)/(max − min) × steps), on a log scale for logarithmic ports
- the same strip can be drawn smaller with `background-size: auto <h>px` (trim pots, or 2× strips on retina)

## Script (optional)

`modgui:javascript` is one anonymous `function (event, funcs) { … }`, called with `event.type` `start` (with `event.ports`) and `change` (`event.symbol`, `event.value`; from the face, a footswitch, MIDI or a preset). Use `event.icon.find(...)` for elements. If it throws, mod-ui silently disables it: keep it small and test it (`tools/face_click_test.py` runs it with mod-ui's own code). Bind click handlers once, on `start`. Don't use `$` (it breaks `define` blocks in recipes); use `event.icon`.

- **`funcs.set_port_value(symbol, value)`** sets a control: the host, the unit's screen and the face's widgets all follow.
- **Swap a strip's artwork with a class.** The film widget only ever sets `background-position`, so a class that changes `background-image` (same frame size) keeps the widget working. MultiPlay swaps its range legend between original and doubled times when Time Mod changes. (Source-checked and tested headless; not yet confirmed on a unit.)
- Other uses: dim controls that are locked by a switch.

## Testing a face

`tools/face_click_test.py <bundle>.lv2` loads the face with mod-ui's own `modgui.js` and jQuery 1.9.1, binds every control exactly as mod-ui does (port data from the TTL), runs the face script, and clicks each control cleanly and with a 2 px mouse wobble. It fails on toggles that drop clicks, momentary switches that don't release, switches whose positions can't be clicked reliably, and script errors; it notes switches that only cycle. Validated on MultiPlay: clean on the fixed face, three failures with the film widgets and no click zones put back.

## Documentation button

`modgui:documentation <modgui/manual.pdf> ;` in `modgui.ttl` turns on the "See documentation" button in the plugin info (mod-ui `utils_lilv.cpp`; source-checked, not yet tried on a unit). MOD asks for this PDF before a plugin leaves beta.

## Screenshot and thumbnail

The screenshot is the face at full size; the thumbnail fits within 256×64. Render after rebuilding the bundle, or you capture old images. `tools/render_face.py <bundle>.lv2` renders both in headless Chromium from the real template, with each control at its TTL default (checked pixel-for-pixel against a hand-tuned render).

## Placeholder faces

Ship a face from the first upload, even a placeholder (see the tuna-can lesson). `tools/placeholder_face.py <bundle>.lv2 --title "Name" --brand "Maker"` reads the TTL and draws one: knobs for numeric ports, switches for toggles and enumerations, a footswitch for bypass, all labelled and marked "placeholder face". It writes `modgui.ttl`, the template, CSS and images, links `modgui.ttl` from the manifest, and renders the screenshot and thumbnail. The art is drawn by the script, so it's free to share. Re-run it after changing ports.

## Real artwork: the workflow that worked

The designer supplies: a background with **black placeholder holes** where controls go, the **knob body and marker as separate layers** at final size, and button on/off states. Then:
- `tools/knob_filmstrip.py body.png marker.png out.png [frames=65] [sweep=270]` builds a strip where the knurl rotates but the lighting stays fixed.
- Fit control positions to the centres of the holes.
- Budget: background JPEG q88, strips as 256-colour PNGs; a whole face of about 200 KB is typical.
- Preview interactively before uploading; the human signs off the look.
