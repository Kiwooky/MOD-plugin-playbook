#!/usr/bin/env python3
"""Generate a simple placeholder pedal face for any plugin bundle, from its TTL.

    python3 tools/placeholder_face.py <bundle>.lv2 [--title "Name"] [--brand "Maker"]

Ships a face from the first upload (a face-less first install leaves a cached
default thumbnail; see docs/lv2-and-mod-rules.md). Writes modgui.ttl and
modgui/ (background, knob strip, switch strip, footswitch, HTML, CSS), adds
modgui.ttl to manifest.ttl, then renders the screenshot and thumbnail with
tools/render_face.py. All art is drawn here (MIT); replace it with real
artwork later. Knobs for numeric ports, switches for toggles/enumerations,
a footswitch for the bypass port. Needs: pillow rdflib (+ playwright).
"""
import argparse, math, os, re, subprocess, sys
import rdflib
from PIL import Image, ImageDraw, ImageFont

L = rdflib.Namespace('http://lv2plug.in/ns/lv2core#')
FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
KN, FR, SW = 56, 65, (48, 28)            # knob size, frames, switch size


def font(sz):
    try:
        return ImageFont.truetype(FONT, sz)
    except OSError:
        return ImageFont.load_default()


def knob_strip(path):
    im = Image.new('RGBA', (KN * FR, KN), (0, 0, 0, 0))
    for f in range(FR):
        d = ImageDraw.Draw(im)
        x0 = f * KN
        d.ellipse((x0 + 4, 4, x0 + KN - 4, KN - 4), fill=(32, 32, 36, 255), outline=(150, 150, 160, 255), width=2)
        a = math.radians(-135 + 270 * f / (FR - 1))
        cx, cy = x0 + KN / 2, KN / 2
        r = KN / 2 - 9
        d.line((cx, cy, cx + r * math.sin(a), cy - r * math.cos(a)), fill=(240, 236, 225, 255), width=4)
    im.save(path, optimize=True)


def switch_strip(path, w, h, led_only=False):
    im = Image.new('RGBA', (w * 2, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for i, on in enumerate((False, True)):
        x0 = i * w
        if not led_only:
            d.rounded_rectangle((x0 + 2, 2, x0 + w - 3, h - 3), radius=6, fill=(45, 45, 50, 255), outline=(150, 150, 160, 255))
        r = min(w, h) // 5
        cx, cy = x0 + w // 2, h // 2 if not led_only else r + 4
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(235, 40, 40, 255) if on else (70, 20, 20, 255))
    im.save(path, optimize=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('bundle'); ap.add_argument('--title'); ap.add_argument('--brand')
    a = ap.parse_args()
    b = a.bundle.rstrip('/')
    name = os.path.basename(b)[:-4]
    g = rdflib.Graph()
    for fn in os.listdir(b):
        if fn.endswith('.ttl') and fn != 'modgui.ttl':
            g.parse(os.path.join(b, fn), format='turtle')
    uri = next(s for s in g.subjects(rdflib.RDF.type, L['Plugin']))
    title = a.title or str(g.value(uri, rdflib.URIRef('http://usefulinc.com/ns/doap#name')) or name)
    brand = a.brand or 'MOD Cookbook'
    knobs, switches, bypass = [], [], None
    ports = []
    for p in g.objects(uri, L['port']):
        if g.value(p, L['index']) is None:
            continue
        ports.append((int(g.value(p, L['index'])), p))
    for _, p in sorted(ports):
        types = set(str(t) for t in g.objects(p, rdflib.RDF.type))
        if str(L['ControlPort']) not in types or str(L['InputPort']) not in types:
            continue
        sym, nm = str(g.value(p, L['symbol'])), str(g.value(p, L['name']))
        props = set(str(o) for o in g.objects(p, L['portProperty']))
        if g.value(p, L['designation']) == L['enabled']:
            bypass = (sym, nm)
        elif str(L['toggled']) in props or str(L['enumeration']) in props:
            switches.append((sym, nm))
        else:
            knobs.append((sym, nm))

    cols = min(max(len(knobs), 1), 5)
    rows = math.ceil(len(knobs) / cols) if knobs else 0
    W = max(420, 40 + cols * 90 + (110 if switches else 0))
    H = 90 + rows * 100 + 150
    md = os.path.join(b, 'modgui'); os.makedirs(md, exist_ok=True)
    cls = re.sub(r'[^a-z0-9]', '', name.lower()) or 'pb'

    bg = Image.new('RGB', (W, H), (52, 58, 66)); d = ImageDraw.Draw(bg)
    d.rectangle((6, 6, W - 7, H - 7), outline=(120, 128, 138), width=2)
    d.text((22, 16), title.upper(), font=font(22), fill=(236, 232, 222))
    d.text((24, 44), brand.upper(), font=font(10), fill=(170, 176, 186))
    d.text((W - 20, 18), 'placeholder face', font=font(9), fill=(150, 156, 166), anchor='ra')
    els, css = [], []
    for i, (sym, nm) in enumerate(knobs):
        x, y = 30 + (i % cols) * 90, 70 + (i // cols) * 100
        d.text((x + KN // 2, y + KN + 8), nm.upper()[:12], font=font(10), fill=(236, 232, 222), anchor='ma')
        els.append('<div class="pb-knob pb-%s" title="%s" mod-role="input-control-port" mod-port-symbol="%s"></div>' % (sym, nm, sym))
        css.append('.%s{{{cns}}} .pb-%s { left: %dpx; top: %dpx; }' % (cls, sym, x, y))
    sx = 40 + cols * 90
    for i, (sym, nm) in enumerate(switches):
        x, y = sx, 76 + i * 64
        d.text((x + SW[0] // 2, y + SW[1] + 6), nm.upper()[:12], font=font(10), fill=(236, 232, 222), anchor='ma')
        els.append('<div class="pb-switch pb-%s" title="%s" mod-widget="switch" mod-role="input-control-port" mod-port-symbol="%s"></div>' % (sym, nm, sym))
        css.append('.%s{{{cns}}} .pb-%s { left: %dpx; top: %dpx; }' % (cls, sym, x, y))
    fy = 70 + rows * 100 + 20
    if bypass:
        d.text((W // 2, fy + 108), 'ON / BYPASS', font=font(10), fill=(236, 232, 222), anchor='ma')
        els.append('<div class="pb-foot" title="Bypass" mod-role="bypass"></div>')
        css.append('.%s{{{cns}}} .pb-foot { left: %dpx; top: %dpx; }' % (cls, W // 2 - 50, fy))
    bg.save(os.path.join(md, 'background.jpg'), quality=88)
    knob_strip(os.path.join(md, 'knob.png'))
    switch_strip(os.path.join(md, 'switch.png'), *SW)
    switch_strip(os.path.join(md, 'footswitch.png'), 100, 100)

    html = '''<div class="mod-pedal %s{{{cns}}}">
    <div mod-role="drag-handle" class="mod-drag-handle"></div>
    %s
    <div class="mod-pedal-input">
        {{#effect.ports.audio.input}}
        <div class="mod-input mod-input-disconnected" title="{{name}}" mod-role="input-audio-port" mod-port-symbol="{{symbol}}">
            <div class="mod-pedal-input-image"></div>
        </div>
        {{/effect.ports.audio.input}}
    </div>
    <div class="mod-pedal-output">
        {{#effect.ports.audio.output}}
        <div class="mod-output mod-output-disconnected" title="{{name}}" mod-role="output-audio-port" mod-port-symbol="{{symbol}}">
            <div class="mod-pedal-output-image"></div>
        </div>
        {{/effect.ports.audio.output}}
    </div>
</div>
''' % (cls, '\n    '.join(els))
    C = '{{{cns}}}'
    style = '''/* Placeholder face generated by tools/placeholder_face.py */
.%(c)s%(C)s { position: absolute; width: %(W)dpx; height: %(H)dpx; border-radius: 4px;
  background-image: url(/resources/background.jpg{{{ns}}}); background-size: %(W)dpx %(H)dpx; }
.%(c)s%(C)s .pb-knob { position: absolute; width: %(K)dpx; height: %(K)dpx; cursor: pointer; z-index: 21;
  background-image: url(/resources/knob.png{{{ns}}}); background-repeat: no-repeat; background-position: 0 0; }
.%(c)s%(C)s .pb-switch { position: absolute; width: %(SW)dpx; height: %(SH)dpx; cursor: pointer; z-index: 21;
  background-image: url(/resources/switch.png{{{ns}}}); background-repeat: no-repeat; }
.%(c)s%(C)s .pb-switch.off { background-position: 0 0; }
.%(c)s%(C)s .pb-switch.on  { background-position: -%(SW)dpx 0; }
.%(c)s%(C)s .pb-foot { position: absolute; width: 100px; height: 100px; cursor: pointer; z-index: 21;
  background-image: url(/resources/footswitch.png{{{ns}}}); background-repeat: no-repeat; }
.%(c)s%(C)s .pb-foot.on  { background-position: 0 0; }       /* bypassed: LED off */
.%(c)s%(C)s .pb-foot.off { background-position: -100px 0; }  /* active: LED lit */
.%(c)s%(C)s .mod-pedal-input, .%(c)s%(C)s .mod-pedal-output { top: %(J)dpx; }
''' % dict(c=cls, C=C, W=W, H=H, K=KN, SW=SW[0], SH=SW[1], J=max(40, H // 2 - 40))
    style += '\n'.join(css) + '\n'
    open(os.path.join(md, 'icon-%s.html' % name), 'w').write(html)
    open(os.path.join(md, 'stylesheet-%s.css' % name), 'w').write(style)

    portlist = ',\n'.join('        [ lv2:index %d ; lv2:symbol "%s" ; lv2:name "%s" ; ]' % (i, s, n)
                          for i, (s, n) in enumerate(knobs + switches))
    open(os.path.join(b, 'modgui.ttl'), 'w').write('''@prefix lv2:    <http://lv2plug.in/ns/lv2core#> .
@prefix modgui: <http://moddevices.com/ns/modgui#> .

<%s>
    modgui:gui [
        modgui:resourcesDirectory <modgui> ;
        modgui:iconTemplate <modgui/icon-%s.html> ;
        modgui:stylesheet <modgui/stylesheet-%s.css> ;
        modgui:screenshot <modgui/screenshot-%s.png> ;
        modgui:thumbnail <modgui/thumbnail-%s.png> ;
        modgui:brand "%s" ;
        modgui:label "%s" ;
        modgui:port
%s ;
    ] .
''' % (uri, name, name, name, name, brand, title, portlist))
    man = os.path.join(b, 'manifest.ttl'); m = open(man).read()
    if 'modgui.ttl' not in m:
        m = re.sub(r'rdfs:seeAlso <([^>]+)>', r'rdfs:seeAlso <\1> , <modgui.ttl>', m, count=1)
        open(man, 'w').write(m)
    print('placeholder face: %d knobs, %d switches%s, %dx%d' % (len(knobs), len(switches), ', bypass' if bypass else '', W, H))
    subprocess.run([sys.executable, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'render_face.py'), b], check=True)


if __name__ == '__main__':
    main()
