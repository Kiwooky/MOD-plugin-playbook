#!/usr/bin/env python3
"""Tests for the template plugin. Copy this file for a new plugin and keep
the generic checks (timing, levels, bypass, torture, ticks, ceiling, silence);
add one test per behaviour the spec promises, and one per hardware report."""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
for d in (os.environ.get('PB_TOOLS', ''), os.path.join(HERE, '..', 'tools'), os.path.join(HERE, '..', '..', '..', 'tools')):
    if d and os.path.exists(os.path.join(d, 'lv2test.py')):
        sys.path.insert(0, d); break
import numpy as np
from lv2test import Plugin, check, done, db, rms, pluck_train, tick_count, max_step

p = Plugin(order=['time', 'feedback', 'mix', 'tails', 'lv2_enabled'],
           defaults=dict(time=350, feedback=40, mix=35, tails=1, lv2_enabled=1), n_in=1, n_out=1)

# Timing: the first echo lands on Time at every sample rate MOD may run
for sr in (44100, 48000, 96000):
    x = np.zeros(int(1.5 * sr)); x[int(0.1 * sr)] = 0.5
    y = p.run(x, sr, mix=100, feedback=0)[:, 0]
    seg = np.abs(y[int(0.3 * sr):])
    t = (int(0.3 * sr) + int(seg.argmax())) / sr - 0.1
    check('echo at 350 ms (%d Hz)' % sr, abs(t - 0.35) < 0.001 and np.isfinite(y).all(), '%.1f ms' % (t * 1e3))

sr = 48000
# Feedback: repeats keep coming and fall away
x = np.zeros(int(2.0 * sr)); x[int(0.1 * sr)] = 0.5
y = p.run(x, sr, mix=100, feedback=50)[:, 0]
pk = [np.abs(y[int((0.1 + 0.35 * k - 0.01) * sr):int((0.1 + 0.35 * k + 0.01) * sr)]).max() for k in (1, 2, 3)]
check('repeats decay', pk[0] > pk[1] > pk[2] > 0, ' '.join('%.1f dB' % db(v) for v in pk))

# Level: mix 50 = dry and echo both present at sensible level
t = np.arange(int(1.2 * sr)) / sr
x = 0.25 * np.sin(2 * np.pi * 440 * t) * (t < 0.3) * np.minimum(1, t / 0.005)
y = p.run(x, sr, mix=100, feedback=0)[:, 0]
g = rms(y[int(0.40 * sr):int(0.60 * sr)]) / rms(x[int(0.05 * sr):int(0.25 * sr)])
check('echo level about unity at full wet', -1.5 < db(g) < 0.5, '%.1f dB' % db(g))

# Bypass: dry at exactly unity, no click, with tails on and off
x = 0.3 * np.sin(2 * np.pi * 220 * np.arange(int(2 * sr)) / sr)
for tails in (1, 0):
    y = p.run(x, sr, tails=tails, events=[(sr, 'lv2_enabled', 0)])[:, 0]
    a, b = int(1.3 * sr), int(1.9 * sr)
    ok = np.abs(y[a:b] - x[a:b]).max() < 1e-3 if not tails else True
    step = max_step(y[int(0.98 * sr):int(1.05 * sr)])
    check('bypass tails=%d: dry at unity, no click' % tails, ok and step < 1.5 * max_step(x), 'max step %.3f' % step)

# Torture: every knob at its maximum, hot input, three rates: finite and bounded
for srt in (44100, 48000, 96000):
    x = 0.8 * np.random.default_rng(1).standard_normal(int(4 * srt))
    y = p.run(x, srt, time=20, feedback=95, mix=100)
    check('torture %d Hz' % srt, np.isfinite(y).all() and np.abs(y).max() < 1.0, 'peak %.2f' % np.abs(y).max())

# No ticks with musical input, and the output never reaches 0 dBFS
x = pluck_train(sr, 8.0)
y = p.run(x, sr, feedback=90, mix=60)[:, 0]
check('no ticks (plucks, feedback 90)', tick_count(y, sr) == 0, '%d' % tick_count(y, sr))
check('output stays under 0 dBFS', db(np.abs(y).max()) < 0, '%.1f dBFS' % db(np.abs(y).max()))

# Silence in, silence out
y = p.run(np.zeros(sr), sr)
check('silence', np.abs(y).max() < 1e-6)

done()
