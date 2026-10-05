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
- Audio jacks: copy the `{{#effect.ports.audio.input}}…` blocks from a stock template.

## CSS

Prefix every selector with `.yourclass{{{cns}}}`; load images as `url(/resources/<file>{{{ns}}})`.

**Filmstrips** (one horizontal row, frame 0 = minimum):
- frames = strip width ÷ **element width** (frames needn't be square)
- frame shown = round((value − min)/(max − min) × steps), on a log scale for logarithmic ports
- the same strip can be drawn smaller with `background-size: auto <h>px` (trim pots, or 2× strips on retina)

## Script (optional)

`modgui:javascript` is one anonymous `function (event, funcs) { … }`, called with `event.type` `start` (with `event.ports`) and `change` (`event.symbol`, `event.value`). Use `event.icon.find(...)` for elements. If it throws, mod-ui silently disables it: keep it small and test it in node first. Example: dim controls that are locked by a switch.

## Screenshot and thumbnail

The screenshot is the face at full size; the thumbnail fits within 256×64. `tools/render_face.py <bundle>.lv2` renders both in headless Chromium from the real template, with each control at its TTL default (checked pixel-for-pixel against a hand-tuned render).

## Placeholder faces

Ship a face from the first upload, even a placeholder (see the tuna-can lesson). `tools/placeholder_face.py <bundle>.lv2 --title "Name" --brand "Maker"` reads the TTL and draws one: knobs for numeric ports, switches for toggles and enumerations, a footswitch for bypass, all labelled and marked "placeholder face". It writes `modgui.ttl`, the template, CSS and images, links `modgui.ttl` from the manifest, and renders the screenshot and thumbnail. The art is drawn by the script, so it's free to share. Re-run it after changing ports.

## Real artwork: the workflow that worked

The designer supplies: a background with **black placeholder holes** where controls go, the **knob body and marker as separate layers** at final size, and button on/off states. Then:
- `tools/knob_filmstrip.py body.png marker.png out.png [frames=65] [sweep=270]` builds a strip where the knurl rotates but the lighting stays fixed.
- Fit control positions to the centres of the holes.
- Budget: background JPEG q88, strips as 256-colour PNGs; a whole face of about 200 KB is typical.
- Preview interactively before uploading; the human signs off the look.
