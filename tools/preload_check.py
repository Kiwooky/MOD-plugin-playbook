#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Find face images the browser only fetches on the first press.

    python3 tools/preload_check.py <bundle>.lv2 [--fix]

A face that swaps art with a class (footswitch.png -> footswitch-down.png
on `.off`, led-off.png -> led-on.png on `.on`, a `.down` button) makes the
browser fetch the second image the first time the class is set, so the
first press of a footswitch shows the old art for a moment. Seen on a
Raspberry Pi 3 running MODEP (Ouraverb's footswitch, 2026-11-22); on a
slow unit or a slow network it is a visible lag.

The fix is a preload rule: the face's root `::after` lists those images in
`content:`, invisible, so they load with the face (docs/modgui.md,
"Preload state art"). This tool lists the images that need it and, with
--fix, adds or updates that rule in the face's stylesheet.

Checks the stylesheet's rules and the face script (images it names).
Exit code 0 always: a missing preload is a lag, not a failure. It prints
"preload: ok" or the images to add.
"""
import os
import re
import sys

# a class or pseudo-class that marks a state the face switches into
STATE = re.compile(r'\.(on|off|down|up|active|pressed|lit|open|is-[\w-]+)\b|:active|:hover|\[aria-pressed')
URL = re.compile(r'url\(\s*["\']?/resources/([^"\'){]+?)(?:\{\{\{ns\}\}\})?["\']?\s*\)')
RULE = re.compile(r'([^{}]+)\{([^{}]*)\}')
MARK = '/* preload: state art fetched with the face (tools/preload_check.py) */'


def ttl_value(ttl, key):
    m = re.search(r'modgui:' + key + r'\s*<([^>]+)>', ttl)
    return m.group(1) if m else None


def strip_mustache(css):
    # {{{cns}}} / {{{ns}}} are inside selectors and URLs; keep them out of the parser's way
    return css.replace('{{{cns}}}', '__CNS__').replace('{{{ns}}}', '')


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    fix = '--fix' in sys.argv
    if len(args) != 1:
        print(__doc__)
        sys.exit(2)
    bundle = args[0].rstrip('/')
    ttl_path = os.path.join(bundle, 'modgui.ttl')
    if not os.path.exists(ttl_path):
        print('preload: no modgui.ttl in %s, nothing to check' % bundle)
        return
    ttl = open(ttl_path, encoding='utf-8').read()
    res = ttl_value(ttl, 'resourcesDirectory') or 'modgui'
    css_rel = ttl_value(ttl, 'stylesheet')
    js_rel = ttl_value(ttl, 'javascript')
    if not css_rel:
        print('preload: no stylesheet, nothing to check')
        return
    css_path = os.path.join(bundle, css_rel)
    raw = open(css_path, encoding='utf-8').read()
    css = re.sub(r'/\*.*?\*/', '', strip_mustache(raw), flags=re.S)

    at_start, in_state, preloaded = set(), set(), set()
    for sel, body in RULE.findall(css):
        urls = set(URL.findall(body))
        if not urls:
            continue
        if re.search(r'\bcontent\s*:', body):
            preloaded |= urls
            continue
        # a selector list: the image loads at start if any selector in it has no state
        sels = [s.strip() for s in sel.split(',') if s.strip()]
        if any(not STATE.search(s) for s in sels):
            at_start |= urls
        else:
            in_state |= urls

    # images the script names (it may set them itself on a change)
    if js_rel and os.path.exists(os.path.join(bundle, js_rel)):
        js = open(os.path.join(bundle, js_rel), encoding='utf-8').read()
        for name in re.findall(r'/resources/([\w.-]+\.(?:png|jpe?g|gif|webp|svg))', js):
            if name not in at_start:
                in_state.add(name)

    missing = sorted(n for n in in_state - at_start - preloaded
                     if os.path.exists(os.path.join(bundle, res, n)))
    if not missing:
        print('preload: ok')
        return
    print('preload: fetched only on first use: ' + ', '.join(missing))
    if not fix:
        print('         add them to a preload rule (docs/modgui.md, "Preload state art"), or run with --fix')
        return

    # --fix: the root class is the first class in the first rule that uses {{{cns}}}
    m = re.search(r'\.([\w-]+)\{\{\{cns\}\}\}', raw)
    if not m:
        print('preload: could not find the face root class ({{{cns}}}); add the rule by hand')
        return
    root = m.group(1)
    want = sorted(set(missing) | preloaded)
    rule = (MARK + '\n.%s{{{cns}}}::after {\n    content: %s;\n'
            '    position: absolute; left: 0; top: 0; width: 0; height: 0;\n'
            '    overflow: hidden; opacity: 0; pointer-events: none;\n}\n') % (
        root, ' '.join('url(/resources/%s{{{ns}}})' % n for n in want))
    if MARK in raw:
        # the rule written last time: from the mark to its closing brace on a line of its own
        raw = re.sub(re.escape(MARK) + r'.*?\n\}\n?', lambda _: rule, raw, count=1, flags=re.S)
    else:
        if re.search(r'\.%s\{\{\{cns\}\}\}::after' % re.escape(root), raw):
            print('preload: .%s::after is already used; add the images to a hidden element instead' % root)
            return
        raw = raw.rstrip('\n') + '\n\n' + rule
    with open(css_path, 'w', encoding='utf-8') as f:
        f.write(raw)
    print('preload: wrote the rule into %s' % css_path)


if __name__ == '__main__':
    main()
