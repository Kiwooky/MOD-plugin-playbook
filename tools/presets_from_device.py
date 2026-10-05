#!/usr/bin/env python3
"""Turn presets saved on a MOD unit into factory presets in your bundle.

1. Fetch them from the unit (USB connected, password "mod"); this writes one
   file to your Desktop, wherever your terminal happens to be:

     ssh root@192.168.51.1 "cd /root/.lv2 && tar czf - <name>-*.lv2" > ~/Desktop/presets.tgz

   (`ls /root/.lv2` on the unit shows them: mod-ui saves each preset as its own
   bundle, <instance>-<Preset_name>.lv2, holding one value per port symbol.)

2. Convert:

     python3 tools/presets_from_device.py bundle/<name>.lv2 presets.tgz \
         [--from-uri <uri the presets were saved with>] [--exclude hold,slam]

Writes <bundle>/presets.ttl and lists each preset in manifest.ttl (between
"# Factory presets" and the end of the file, replaced on every run), with URIs
<plugin URI>#preset-<Name>. Then re-reads the bundle and checks every value
against the source presets.

- --from-uri: the URI the presets point at, if it differs from the bundle's
  (e.g. presets made on a prototype before the plugin got its final URI).
  Default: presets that apply to the bundle's own URI.
- --exclude: port symbols to leave out, typically footswitch states (hold, freeze,
  momentary switches) so loading a preset never latches anything. The bypass
  (lv2:enabled) port is always left out.
- Symbols the plugin no longer has are dropped; ports a preset doesn't mention
  keep their current value when it loads. Both are reported.

Needs: pip install rdflib.
"""
import argparse, os, re, sys, tarfile, tempfile
import rdflib

L = rdflib.Namespace('http://lv2plug.in/ns/lv2core#')
PSET = rdflib.Namespace('http://lv2plug.in/ns/ext/presets#')
RDFS = rdflib.RDFS
MARK = '# Factory presets'


def parse_dir(path):
    g = rdflib.Graph()
    for root, _, files in os.walk(path):
        for fn in files:
            if fn.endswith('.ttl'):
                g.parse(os.path.join(root, fn), format='turtle', publicID='file://' + os.path.join(root, fn))
    return g


def plugin_info(bundle):
    g = rdflib.Graph()
    for fn in os.listdir(bundle):
        if fn.endswith('.ttl') and fn != 'presets.ttl':
            g.parse(os.path.join(bundle, fn), format='turtle')
    uri = next(s for s in g.subjects(rdflib.RDF.type, L['Plugin']))
    ports = {}
    for p in g.objects(uri, L['port']):
        sym = g.value(p, L['symbol'])
        if sym is None or (p, rdflib.RDF.type, L['ControlPort']) not in g or (p, rdflib.RDF.type, L['InputPort']) not in g:
            continue
        props = {str(o).split('#')[-1] for o in g.objects(p, L['portProperty'])}
        ports[str(sym)] = {'int': bool(props & {'integer', 'toggled', 'enumeration'}),
                           'bypass': g.value(p, L['designation']) is not None}
    return str(uri), ports


def fmt(v, is_int):
    if is_int:
        return str(int(round(v)))
    s = repr(float(v))
    return s if ('.' in s or 'e' in s) else s + '.0'


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('bundle')
    ap.add_argument('source', help='the .tgz from the unit, or a folder of preset bundles')
    ap.add_argument('--from-uri')
    ap.add_argument('--exclude', default='')
    a = ap.parse_args()
    bundle = a.bundle.rstrip('/')
    uri, ports = plugin_info(bundle)
    src_uri = a.from_uri or uri
    exclude = {s for s in a.exclude.split(',') if s}

    with tempfile.TemporaryDirectory() as td:
        src = a.source
        if os.path.isfile(src):
            with tarfile.open(src) as t:
                try:
                    t.extractall(td, filter='data')
                except TypeError:          # Python < 3.12
                    t.extractall(td)
            src = td
        g = parse_dir(src)
        found = []
        for pr in g.subjects(rdflib.RDF.type, PSET['Preset']):
            if str(g.value(pr, L['appliesTo'])) != src_uri or g.value(pr, L['port']) is None:
                continue
            label = str(g.value(pr, RDFS.label))
            vals = {str(g.value(pt, L['symbol'])): float(g.value(pt, PSET['value'])) for pt in g.objects(pr, L['port'])}
            found.append((label, vals))
    if not found:
        sys.exit('no presets for %s in %s (use --from-uri if they were saved with another URI)' % (src_uri, a.source))
    found.sort(key=lambda x: x[0].lower())

    out = ['@prefix lv2:  <http://lv2plug.in/ns/lv2core#> .',
           '@prefix pset: <http://lv2plug.in/ns/ext/presets#> .',
           '@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .', '']
    man, expect, used = [], {}, set()
    for label, vals in found:
        slug = re.sub(r'[^A-Za-z0-9]+', '_', label).strip('_') or 'preset'
        while slug in used:
            slug += '_'
        used.add(slug)
        puri = '%s#preset-%s' % (uri, slug)
        keep = {s: v for s, v in vals.items() if s in ports and not ports[s]['bypass'] and s not in exclude}
        dropped = sorted(s for s in vals if s not in ports)
        missing = sorted(s for s in ports if s not in vals and not ports[s]['bypass'] and s not in exclude)
        expect[puri] = {s: float(fmt(v, ports[s]['int'])) for s, v in keep.items()}
        body = '\n    ] , [\n'.join('        lv2:symbol "%s" ;\n        pset:value %s' % (s, fmt(v, ports[s]['int']))
                                     for s, v in sorted(keep.items()))
        out.append('<%s>\n    a pset:Preset ;\n    lv2:appliesTo <%s> ;\n    rdfs:label "%s" ;\n    lv2:port [\n%s\n    ] .\n'
                   % (puri, uri, label.replace('"', '\\"'), body))
        man.append('<%s>\n    a pset:Preset ;\n    lv2:appliesTo <%s> ;\n    rdfs:label "%s" ;\n    rdfs:seeAlso <presets.ttl> .\n'
                   % (puri, uri, label.replace('"', '\\"')))
        note = []
        if dropped:
            note.append('dropped (not in plugin): ' + ', '.join(dropped))
        if missing:
            note.append('not in preset, keeps current value: ' + ', '.join(missing))
        print('%-28s %2d values%s' % (label, len(keep), ('  [' + '; '.join(note) + ']') if note else ''))

    open(os.path.join(bundle, 'presets.ttl'), 'w').write('\n'.join(out))
    mpath = os.path.join(bundle, 'manifest.ttl')
    m = open(mpath).read()
    if MARK in m:
        m = m[:m.index(MARK)].rstrip('\n') + '\n'
    if 'ns/ext/presets#' not in m:
        m = '@prefix pset: <http://lv2plug.in/ns/ext/presets#> .\n' + m
    if '@prefix rdfs:' not in m:
        m = '@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .\n' + m
    open(mpath, 'w').write(m.rstrip('\n') + '\n\n' + MARK + '\n' + '\n'.join(man))

    # verify: read the bundle back and compare every value
    g = parse_dir(bundle)
    bad = n = 0
    for puri, want in expect.items():
        pr = rdflib.URIRef(puri)
        if (pr, rdflib.RDF.type, PSET['Preset']) not in g or (pr, RDFS.seeAlso, None) not in g:
            print('MISSING in manifest/presets:', puri); bad += 1; continue
        got = {str(g.value(pt, L['symbol'])): float(g.value(pt, PSET['value'])) for pt in g.objects(pr, L['port'])}
        for s, v in want.items():
            n += 1
            if s not in got or abs(got[s] - v) > 1e-9:
                print('MISMATCH', puri, s, got.get(s), v); bad += 1
    print('\n%d presets, %d values written and read back, %d problems' % (len(expect), n, bad))
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
