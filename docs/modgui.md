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

`modgui:javascript` is one anonymous `function (event, funcs) { … }`, called with `event.type` `start` (with `event.ports`) and `change` (`event.symbol`, `event.value`; from the face, a footswitch, MIDI or a preset). Use `event.icon.find(...)` for elements. If it throws, mod-ui silently disables it: keep it small and test it (`tools/face_click_test.py` runs it with mod-ui's own code). Bind click handlers once, on `start`. Don't use `$` (it breaks `define` blocks in recipes); use `event.icon` and `jQuery(...)`.

- **`funcs.set_port_value(symbol, value)`** sets a control: the host, the unit's screen and the face's widgets all follow. **The script itself gets no `change` event for its own sets** (mod-ui's `"from-js"` source), so redraw whatever the script draws right after setting. Values from a footswitch, MIDI, a preset or a widget do arrive as `change`. (Source-checked in `modgui.js`, tested.)
- **`event.data` is one object for the face's lifetime** (mod-ui's `jsData`): keep the script's state there.
- **Script-driven controls:** plain elements (no `mod-role`) that the script binds on `start` and that call `funcs.set_port_value`. Mark each with an attribute whose value is the port symbol (`<div my-switch="tails">`, `<div my-bank="echo_taps" my-bit="0">`): the script finds them with it, and so does `tools/face_click_test.py`. Handle `touchstart` as well as `mousedown` (`preventDefault`, and ignore emulated mouse events for about 1 s after a touch), and act on press. EC-280's Tail, Range and mode switches work this way after the film widget failed on a Duo; tested with mod-ui's code, mouse and touch.
- **Radio banks with "hold to add":** one integer port per bank holding a bitmask (1–15 for four buttons, each value with a scale point like `E1+E3`, so the unit's screen, footswitch stepping and presets all work). The script: tap = that button only; hold about 0.5 s (fire while still held) or shift-click = add or remove it; the last button down can't be removed. EC-280's Echo and Reverb banks (the original latched several buttons only if pressed together). Tested with mouse and touch.
- **Swap a strip's artwork with a class.** The film widget only ever sets `background-position`, so a class that changes `background-image` (same frame size) keeps the widget working. MultiPlay swaps its range legend between original and doubled times when Time Mod changes. (Source-checked and tested headless; not yet confirmed on a unit.)
- Other uses: dim controls that are locked by a switch.

## Testing a face

`tools/face_click_test.py <bundle>.lv2` loads the face with mod-ui's own `modgui.js` and jQuery 1.9.1, binds every control exactly as mod-ui does (port data from the TTL), runs the face script with mod-ui's semantics (persistent `event.data`, no `change` back for the script's own sets), and presses each control from its TTL default: cleanly, with a 2 px mouse wobble, and (toggles) with touch taps. Script-driven controls are found by the attribute that names their port. It fails on toggles that drop a press, momentary switches that don't release, switches whose positions can't be clicked reliably, script controls that never set a value or give different values for a wobbly click, and script errors; it notes switches that only cycle. Validated on MultiPlay (clean on the fixed face, three failures with the film widgets and no click zones put back) and EC-280 (clean on 1.0.0; exactly the three switches that failed on the Duo when the 1.0.1 face is put back; three failures when the script's switch handler is emptied).

**Run it before blaming the device.** EC-280 1.0.1 was built without this playbook; its film-widget switches "switched once, then never back" on a Duo, and the first guess was a stale cache. This tool reproduces that failure exactly.

## Documentation button

`modgui:documentation <modgui/manual.pdf> ;` in `modgui.ttl` turns on the "See documentation" button in the plugin info (mod-ui `utils_lilv.cpp`; source-checked, not yet tried on a unit). MOD asks for this PDF before a plugin leaves beta.

## Screenshot and thumbnail

The screenshot is the face at full size; the thumbnail fits within 256×64. Render after rebuilding the bundle, or you capture old images. `tools/render_face.py <bundle>.lv2` renders both in headless Chromium from the real template, with each control at its TTL default (checked pixel-for-pixel against a hand-tuned render).

## Placeholder faces

Ship a face from the first upload, even a placeholder (see the tuna-can lesson). `tools/placeholder_face.py <bundle>.lv2 --title "Name" --brand "Maker"` reads the TTL and draws one: knobs for numeric ports, switches for toggles and enumerations, a footswitch for bypass, all labelled and marked "placeholder face". It writes `modgui.ttl`, the template, CSS and images, links `modgui.ttl` from the manifest, and renders the screenshot and thumbnail. The art is drawn by the script, so it's free to share. Re-run it after changing ports.

## Real artwork: the workflow that worked

The designer supplies: a background with **black placeholder holes** where controls go, the **knob body and marker as separate layers** at final size, and button on/off states. Then:
- `tools/knob_filmstrip.py body.png marker.png out.png [frames=65] [sweep=270]` builds a strip where the knurl rotates but the lighting stays fixed. **Measure the sweep from the printed scale, don't assume 270°:** sample the background in a ring around a knob centre, find the scale marks' angles, and use the span from 0 to max. EC-280's scale spans 276° (0 at 228°, 27.6° a step); with that sweep the pointer lands on every number (render-checked).
- Fit control positions to the centres of the holes. **If the designer sent a mockup, fit by template matching:** composite each sprite onto the background at candidate positions near the hole and keep the one with the least pixel error against the mockup. EC-280: zero error for every button and switch.
- **Output jacks can sit on printed legends.** mod-ui draws each jack 56 px tall with a 13 px gap (69 px pitch), starting at the `.mod-pedal-output` element's `top`. Set that `top`, and change the pitch with `.mod-pedal.<yourclass>{{{cns}}} .mod-pedal-output .mod-audio-output { margin-bottom: … }`. EC-280's jacks sit on its MIX and 100% WET arrows (rendered with mod-ui's CSS rules; not yet seen on a unit).
- **When the art names a control differently, change port names and scale-point labels, never symbols.** EC-280's face says REVERB where the ports said "Hall": the unit's screen now matches the art and saved settings still load.
- Budget: background JPEG q88, strips as 256-colour PNGs; a whole face of about 200 KB is typical.
- Preview interactively before uploading; the human signs off the look.
