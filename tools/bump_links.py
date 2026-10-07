#!/usr/bin/env python3
"""Stamp the playbook's own GitHub links with ?v=<version>, then rebuild ALL-IN-ONE.md.

    python3 tools/bump_links.py 0.4.1

Why: AI fetch services cache GitHub pages, sometimes for hours. After a push, the plain
link to AGENTS.md can still serve the old file (seen with the 0.4.0 release: the fetch
returned the pre-0.4.0 AGENTS.md while ?v=0.4.0 returned the new one). A new query
string is a new cache key. Run this, with a new version, before every push that
changes AGENTS.md, the docs or the template, and add the version to CHANGELOG.md.
"""
import os, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LINK = re.compile(r'(https://github\.com/Kiwooky/MOD-plugin-playbook/blob/main/[^\s)>?`]+)(\?v=[\w.-]+)?')

if len(sys.argv) != 2 or not re.fullmatch(r'[\w.-]+', sys.argv[1]):
    sys.exit(__doc__)
v = sys.argv[1]
for f in ('README.md', 'AGENTS.md'):
    p = os.path.join(ROOT, f)
    s = open(p).read()
    s2, n = LINK.subn(lambda m: '%s?v=%s' % (m.group(1), v), s)
    open(p, 'w').write(s2)
    print('%s: %d links -> ?v=%s' % (f, n, v))
subprocess.run([sys.executable, os.path.join(ROOT, 'tools', 'make_all_in_one.py')] + sys.argv[2:], check=True)
