#!/usr/bin/env python3
"""Give a plugin one of MOD's stock pedal faces (the MOD SDK's templates), picked from its ports.

    python3 tools/stock_face.py --list                                   # styles, sizes, colours
    python3 tools/stock_face.py <bundle>.lv2 --style japanese --color red --knob black \
        [--title "Name"] [--brand "Maker"] [--stomp <toggle symbol> ...] [--dry-run]

Styles (from mod-sdk's html/resources):
  boxy      Hammond-style box (DIY, MXR-like). 1-8 knobs, one selector + 1-4 knobs, 9-12 sliders.
            Grows wider with more controls. Takes extra footswitches (--stomp).
  japanese  Compact stompbox with the big rocker footswitch (Boss-like). 4-8 knobs.
  british   Metallic box, 4 knobs.
  lata      Tin can, 7-8 knobs.
  (0 knobs -> boxy-small, a footswitch-only box.)

What lands on the face: knobs = numeric control ports in port order; on boxy, the first
enumeration becomes a selector. Toggles and other enumerations stay off the face (they're
still in the plugin's settings and assignable to the unit's footswitches) unless named with
--stomp, which adds them as extra footswitches (boxy only, up to 2 extra; the box widens).

Writes modgui.ttl and modgui/ (template pre-rendered with the real ports, CSS, the art it
needs, 256-colour PNGs to keep a single-file recipe small), links modgui.ttl from
manifest.ttl, then renders the screenshot and thumbnail with tools/render_face.py using
MOD's own fonts. Art is fetched from mod-sdk at a pinned commit into $PB_CACHE.

Licence: the stock art and templates are mod-sdk's (GPL-3.0), like the playbook and its template.
They ship inside your bundle; credit mod-sdk in the plugin's README.
Needs: pillow rdflib (+ playwright for the screenshot).
"""
import argparse, io, json, os, re, subprocess, sys, urllib.request
import rdflib
from PIL import Image

SDK_SHA = 'ba1e9be87b7cb50cf18169649b2cffa9c7dd2c9d'      # mod-sdk, 2023-06-15
UI_SHA = 'master'                                          # mod-ui fonts (render only)
SDK = 'https://raw.githubusercontent.com/mod-audio/mod-sdk/%s/html/' % SDK_SHA
UI = 'https://raw.githubusercontent.com/mod-audio/mod-ui/%s/html/' % UI_SHA
CACHE = os.path.join(os.environ.get('PB_CACHE', os.path.expanduser('~/.cache/mod-playbook')), 'mod-sdk-' + SDK_SHA[:8])
L = rdflib.Namespace('http://lv2plug.in/ns/lv2core#')
DOAP = rdflib.Namespace('http://usefulinc.com/ns/doap#')
NUM = {1: 'one', 2: 'two', 3: 'three', 4: 'four', 5: 'five', 6: 'six', 7: 'seven', 8: 'eight'}


def fetch(rel, base=SDK, cache=CACHE):
    p = os.path.join(cache, rel)
    if not os.path.exists(p):
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with urllib.request.urlopen(base + rel) as r:
            data = r.read()
        open(p, 'wb').write(data)
    return p


def wizard():
    return json.load(open(fetch('resources/wizard.json')))


# ---------------------------------------------------------------- choosing a layout

def choose(style, n, has_enum, stomps):
    """-> (model, panel, size suffix for the boxy art folder, list of notes)"""
    notes = []
    if stomps and style not in ('boxy', 'auto'):
        notes.append('extra footswitches need the boxy style; using boxy')
        style = 'boxy'
    if style == 'auto':
        style = 'boxy'
    if n == 0 and not has_enum:
        return 'boxy-small', '1-footswitch', '', notes
    if style == 'japanese':
        if n > 8: raise SystemExit('japanese takes up to 8 knobs (this has %d); try boxy' % n)
        return 'japanese', {6: '7-a-knobs', 7: '7-a-knobs', 8: '8-knobs', 5: '5-knobs'}.get(n, '4-knobs'), '', notes
    if style == 'british':
        if n > 4: raise SystemExit('british takes up to 4 knobs (this has %d)' % n)
        return 'british', '4-knobs', '', notes
    if style == 'lata':
        if n > 8: raise SystemExit('lata takes up to 8 knobs (this has %d)' % n)
        return 'lata', '8-knobs' if n == 8 else '7-knobs', '', notes
    if style != 'boxy':
        raise SystemExit('unknown style %s' % style)
    if has_enum and 1 <= n <= 4:
        panel = '1-select-%d-knob%s' % (n, '' if n == 1 else 's')
    elif n <= 8:
        panel = '%d-knob%s' % (max(n, 1), '' if n == 1 else 's')
    elif n <= 12:
        panel = '%d-sliders' % (12 if n == 11 else n)
        notes.append('more than 8 controls: sliders')
    else:
        raise SystemExit('more than 12 controls; a stock face can\'t hold them all (custom face territory)')
    suffix = {'12-sliders': '100', '10-sliders': '85'}.get(panel, '')
    if panel in ('9-sliders', '8-sliders', '7-sliders', '8-knobs', '7-knobs', '4-knobs', '1-select-4-knobs'):
        suffix = '75'
    if stomps:                                     # wider box for more footswitches
        order = ['', '75', '85', '100']
        need = {1: '75', 2: '100'}[len(stomps)]
        suffix = max(suffix, need, key=order.index)
    return 'boxy', panel, suffix, notes


# ---------------------------------------------------------------- mustache (the subset the templates use)

def render(tpl, ctx):
    """Expand {{#controls}}, {{#controls.N}}, {{#scalePoints}} and {{var}}; leave {{{cns}}},
    {{{ns}}} and the {{#effect...}} sections for mod-ui."""
    def sect(m):
        name, body = m.group(1), m.group(2)
        if name.startswith('effect.'):
            return m.group(0)
        val = ctx[-1].get(name) if '.' not in name else None
        if '.' in name:
            base, idx = name.split('.')
            lst = ctx[-1].get(base) or []
            val = lst[int(idx)] if int(idx) < len(lst) else None
        if not val:
            return ''
        items = val if isinstance(val, list) else [val]
        return ''.join(render(body, ctx + [it]) for it in items)
    out = re.sub(r'\{\{#([\w.]+)\}\}(.*?)\{\{/\1\}\}', sect, tpl, flags=re.S)

    def var(m):
        k = m.group(1)
        for c in reversed(ctx):
            if k in c:
                return str(c[k]).replace('&', '&amp;').replace('<', '&lt;').replace('"', '&quot;')
        return ''
    return re.sub(r'(?<!\{)\{\{(\w+)\}\}(?!\})', var, out)


# ---------------------------------------------------------------- the bundle

def read_ports(b):
    g = rdflib.Graph()
    for fn in os.listdir(b):
        if fn.endswith('.ttl') and fn != 'modgui.ttl':
            g.parse(os.path.join(b, fn), format='turtle')
    uri = next(s for s in g.subjects(rdflib.RDF.type, L['Plugin']))
    knobs, enums, toggles = [], [], []
    ports = sorted((int(g.value(p, L['index'])), p) for p in g.objects(uri, L['port']) if g.value(p, L['index']) is not None)
    for _, p in ports:
        types = set(str(t) for t in g.objects(p, rdflib.RDF.type))
        if str(L['ControlPort']) not in types or str(L['InputPort']) not in types:
            continue
        if g.value(p, L['designation']) == L['enabled']:
            continue
        props = set(str(o) for o in g.objects(p, L['portProperty']))
        d = dict(symbol=str(g.value(p, L['symbol'])), name=str(g.value(p, L['name'])),
                 comment=str(g.value(p, rdflib.RDFS.comment) or g.value(p, L['name'])),
                 default=float(g.value(p, L['default']) or 0))
        if str(L['enumeration']) in props:
            d['scalePoints'] = sorted(({'value': float(g.value(sp, rdflib.RDF.value)), 'label': str(g.value(sp, rdflib.RDFS.label))}
                                       for sp in g.objects(p, L['scalePoint'])), key=lambda s: s['value'])
            for s in d['scalePoints']:
                s['value'] = ('%g' % s['value'])
            enums.append(d)
        elif str(L['toggled']) in props:
            toggles.append(d)
        else:
            knobs.append(d)
    title = str(g.value(uri, DOAP['name']) or os.path.basename(b)[:-4])
    return g, uri, title, knobs, enums, toggles


def quantize(src, dst):
    im = Image.open(src).convert('RGBA')
    q = im.quantize(256, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE)
    q.save(dst, optimize=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('bundle', nargs='?')
    ap.add_argument('--list', action='store_true')
    ap.add_argument('--style', default='auto', choices=['auto', 'boxy', 'japanese', 'british', 'lata'])
    ap.add_argument('--color'); ap.add_argument('--knob')
    ap.add_argument('--title'); ap.add_argument('--brand')
    ap.add_argument('--stomp', action='append', default=[], help='toggle port symbol to put on its own footswitch (boxy)')
    ap.add_argument('--no-quantize', action='store_true')
    ap.add_argument('--dry-run', action='store_true', help='print the choice, write nothing')
    ap.add_argument('--fetch-at-build', action='store_true',
                    help='ship only modgui.ttl, screenshot and thumbnail; the recipe downloads the SDK template, CSS and art at build time (verified on builder.mod.audio)')
    a = ap.parse_args()
    W = wizard()
    if a.list:
        for m in ('boxy', 'boxy-small', 'japanese', 'british', 'lata'):
            v = W[m]
            print('%-10s panels: %s\n%-10s colors: %s%s' % (m, ', '.join(v['panels']), '', ', '.join(v.get('colors', [])),
                  ('\n%-10s knobs:  %s' % ('', ', '.join(v['knobs']))) if v.get('knobs') else ''))
        return
    if not a.bundle:
        ap.error('bundle required')
    b = a.bundle.rstrip('/')
    name = os.path.basename(b)[:-4]
    g, uri, title, knobs, enums, toggles = read_ports(b)
    title = a.title or title
    brand = a.brand or 'MOD Cookbook'
    stomps = [t for t in toggles if t['symbol'] in a.stomp]
    missing = set(a.stomp) - set(t['symbol'] for t in stomps)
    if missing:
        raise SystemExit('--stomp needs toggle ports; not toggles here: %s' % ', '.join(sorted(missing)))
    if len(stomps) > 2:
        raise SystemExit('at most 2 extra footswitches on a stock box')
    model, panel, suffix, notes = choose(a.style, len(knobs), bool(enums), stomps)
    use_enum = model == 'boxy' and panel.startswith('1-select')
    controls = ([enums[0]] if use_enum else []) + knobs if model != 'boxy-small' else []
    off = [c['name'] for c in toggles if c not in stomps] + [e['name'] for e in (enums[1:] if use_enum else enums)]
    info = W[model]
    color = a.color or ('black' if 'black' in info.get('colors', []) else info['colors'][0])
    knob = a.knob or (info['knobs'][0] if info.get('knobs') else None)
    if model == 'boxy' and not a.knob:
        knob = 'aluminium'
    if color not in info['colors']:
        raise SystemExit('colour %s not available for %s: %s' % (color, model, ', '.join(info['colors'])))
    if knob and info.get('knobs') and knob not in info['knobs']:
        raise SystemExit('knob %s not available for %s: %s' % (knob, model, ', '.join(info['knobs'])))
    print('face: %s %s%s, colour %s%s; on the face: %s%s' % (
        model, panel, (' (boxy%s width)' % suffix) if suffix else '', color, (', knobs ' + knob) if knob else '',
        ', '.join(c['name'] for c in controls) or 'footswitch only',
        ('; extra footswitches: ' + ', '.join(s['name'] for s in stomps)) if stomps else ''))
    if off:
        print('off the face (still in settings and assignable): ' + ', '.join(off))
    for n in notes:
        print('note: ' + n)
    if a.dry_run:
        return
    if a.fetch_at_build and (stomps or use_enum):
        raise SystemExit('--fetch-at-build uses the SDK template as is: no --stomp, and no boxy selector (use a knob-only panel)')

    # ---- template
    tpl = open(fetch('resources/templates/pedal-%s-%s.html' % (model, panel))).read()
    html = render(tpl, [dict(brand=brand, label=title, color=color, knob=knob or '', controls=controls)])
    if use_enum:                          # show the default choice in the screenshot; mod-ui keeps it current
        e = enums[0]
        lab = next((sp['label'] for sp in e['scalePoints'] if float(sp['value']) == e['default']), '')
        html = html.replace('class="mod-enumerated-selected"></div>', 'class="mod-enumerated-selected">%s</div>' % lab, 1)
    if stomps:
        html = add_stomps(html, stomps, suffix)

    # ---- css and art
    fam = 'boxy' if model.startswith('boxy') else model
    css = open(fetch('resources/pedals/%s/%s.css' % (fam, fam))).read()
    kcss = 'resources/knobs/%s/%s.css' % (fam, fam)
    if model != 'boxy-small' and fam != 'british':
        css += '\n' + open(fetch(kcss)).read()
    if stomps:
        css += stomp_css(len(stomps))
    md = os.path.join(b, 'modgui'); os.makedirs(md, exist_ok=True)
    art_dir = {'boxy': 'pedals/boxy%s' % suffix, 'boxy-small': 'pedals/boxy-small'}.get(model, 'pedals/%s' % model)
    colors, knobcols = set(info.get('colors', [])), set(info.get('knobs', []))
    need = set()
    for u in set(re.findall(r'url\(/resources/([^){]+)', css)):
        d, stem = os.path.dirname(u), os.path.splitext(os.path.basename(u))[0]
        if d.startswith('pedals/') and d != 'pedals' and stem in colors | {'none'}:
            if d == art_dir and stem == color:
                need.add(u)
        elif d.startswith('knobs/'):
            if stem == knob or (not knob and stem == fam):
                need.add(u)
        elif u == 'pedals/slider.png':
            if 'sliders' in panel:
                need.add(u)
        elif u.startswith('utils/dropdown-arrow'):
            if 'select' in panel:
                need.add(u)
        else:
            need.add(u)
    if model == 'boxy':                   # the art folder for the size class isn't named in CSS by colour rule alone
        need.add('%s/%s.png' % (art_dir, color))
    total = 0
    for u in sorted(need):
        try:
            src = fetch('resources/' + u)
        except Exception:
            continue                      # referenced but not shipped by the SDK (e.g. a size the panel doesn't use)
        dst = os.path.join(md, u); os.makedirs(os.path.dirname(dst), exist_ok=True)
        if u.endswith('.png') and not a.no_quantize:
            quantize(src, dst)
        else:
            open(dst, 'wb').write(open(src, 'rb').read())
        total += os.path.getsize(dst)
    if model == 'boxy' and suffix:        # point the size class at its own art folder
        css += '\n.mod-pedal-boxy{{{cns}}}.mod-boxy%s.mod-%s { background-image:url(/resources/%s/%s.png{{{ns}}}); }\n' % (suffix, color, art_dir, color)
        if 'mod-boxy%s' % suffix not in html:
            html = html.replace('mod-pedal-boxy{{{cns}}}', 'mod-pedal-boxy{{{cns}}} mod-boxy%s' % suffix, 1)
    css = '/* MOD SDK stock face (%s %s), mod-sdk %s, GPL-3.0. Written by tools/stock_face.py */\n' % (model, panel, SDK_SHA[:8]) + css
    open(os.path.join(md, 'icon-%s.html' % name), 'w').write(html)
    open(os.path.join(md, 'stylesheet-%s.css' % name), 'w').write(css)

    portlist = ',\n'.join('        [ lv2:index %d ; lv2:symbol "%s" ; lv2:name "%s" ; ]' % (i, c['symbol'], c['name'])
                          for i, c in enumerate(controls + stomps))
    ttl = '''@prefix lv2:    <http://lv2plug.in/ns/lv2core#> .
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
        modgui:model "%s" ;
        modgui:panel "%s" ;
        modgui:color "%s" ;
%s%s    ] .
''' % (uri, name, name, name, name, brand, title, model, panel, color,
       ('        modgui:knob "%s" ;\n' % knob) if knob else '',
       ('        modgui:port\n%s ;\n' % portlist) if portlist else '')
    open(os.path.join(b, 'modgui.ttl'), 'w').write(ttl)
    man = os.path.join(b, 'manifest.ttl'); m = open(man).read()
    if 'modgui.ttl' not in m:
        m = re.sub(r'rdfs:seeAlso <([^>]+)>', r'rdfs:seeAlso <\1> , <modgui.ttl>', m, count=1)
        open(man, 'w').write(m)
    print('art: %d files, %d KB' % (len(need), total // 1024))

    # ---- fonts for the screenshot (mod-ui serves them on the unit)
    fonts = os.path.join(CACHE, 'fonts')
    # mod-ui loads Nexa and Questrial page-wide; some stock CSS relies on that without importing them
    for f in set(re.findall(r'@import url\(/fonts/([^)]+)\)', css)) | {'nexa/stylesheet.css', 'questrial/stylesheet.css'}:
        sheet = fetch('fonts/' + f, UI, CACHE)
        for ff in re.findall(r'url\([\'"]?([^\'")]+)', open(sheet).read()):
            if not ff.startswith(('data:', 'http')):
                try:
                    fetch(os.path.normpath(os.path.join('fonts', os.path.dirname(f), ff.split('?')[0].split('#')[0])), UI, CACHE)
                except Exception:
                    pass
    env = dict(os.environ, PB_FONTS_DIR=fonts)
    subprocess.run([sys.executable, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'render_face.py'), b], check=True, env=env)

    if a.fetch_at_build:
        # keep modgui.ttl (model/panel/color/knob/ports: mod-ui renders the SDK template from them),
        # the screenshot and the thumbnail; list everything else for the recipe to download
        base = SDK + 'resources/'
        csss = ['pedals/%s/%s.css' % (fam, fam)] + ([kcss[len('resources/'):]] if model != 'boxy-small' and fam != 'british' else [])
        lines = ['# Downloaded at build time by the recipe (tools/assemble_recipe.py). mod-sdk %s, GPL-3.0.' % SDK_SHA[:8],
                 '# <path in modgui/>  <url> [<url> ...]   (several urls are joined into one file)',
                 'icon-%s.html  %stemplates/pedal-%s-%s.html' % (name, base, model, panel),
                 'stylesheet-%s.css  %s' % (name, '  '.join(base + c for c in csss))]
        lines += ['%s  %s%s' % (u, base, u) for u in sorted(need) if os.path.exists(os.path.join(CACHE, 'resources', u))]
        import shutil
        for f in os.listdir(md):
            if not f.startswith(('screenshot-', 'thumbnail-')):
                full = os.path.join(md, f)
                shutil.rmtree(full) if os.path.isdir(full) else os.remove(full)
        open(os.path.join(md, 'FETCH.txt'), 'w').write('\n'.join(lines) + '\n')
        print('fetch at build: %d files listed in modgui/FETCH.txt' % (len(lines) - 2))


# ---------------------------------------------------------------- extra footswitches (boxy)

def add_stomps(html, stomps, suffix):
    els = ''.join('\n    <div class="mod-footswitch pb-stomp pb-stomp-%d" title="%s" mod-role="input-control-port" mod-port-symbol="%s" mod-widget="switch"></div>'
                  '\n    <div class="pb-stomp-label pb-stomp-label-%d">%s</div>' % (i + 1, s['name'], s['symbol'], i + 1, s['name'].upper())
                  for i, s in enumerate(stomps))
    els += '\n    <div class="pb-stomp-label pb-stomp-label-0">ON</div>'
    return html.replace('<div class="mod-footswitch" mod-role="bypass"></div>',
                        '<div class="mod-footswitch pb-bypass" mod-role="bypass"></div>' + els, 1)


def stomp_css(n):
    cols = n + 1
    C = '.mod-pedal-boxy{{{cns}}}'
    out = ['\n/* extra footswitches (tools/stock_face.py) */']
    for i, sel in enumerate(['.pb-bypass'] + ['.pb-stomp-%d' % (k + 1) for k in range(n)]):
        out.append('%s .mod-footswitch%s { left: calc(13px + %d * (100%% - 26px) / %d); right: auto; width: calc((100%% - 26px) / %d); }'
                   % (C, sel, i, cols, cols))
        lab = 0 if i == 0 else i
        out.append('%s .pb-stomp-label-%d { position:absolute; bottom: 165px; left: calc(13px + %d * (100%% - 26px) / %d); width: calc((100%% - 26px) / %d);'
                   ' text-align:center; font-family:"Questrial"; font-size:11px; color:#222; text-transform:uppercase; }' % (C, lab, i, cols, cols))
    out.append('%s .mod-footswitch.pb-stomp.off { background-position-y: top !important; }' % C)
    out.append('%s .mod-footswitch.pb-stomp.on { background-position-y: bottom !important; }' % C)
    return '\n'.join(out) + '\n'


if __name__ == '__main__':
    main()
