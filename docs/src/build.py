#!/usr/bin/env python3
"""Inline fonts and screens into docs/index.html so it renders even where
sibling files cannot load (previews, snapshots). Videos stay as media/ files.
Run from anywhere: python3 docs/src/build.py"""
import base64, os, re, subprocess, tempfile
D = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
s = open(os.path.join(D, 'src', 'index.src.html'), encoding='utf-8').read()
tmp = tempfile.mkdtemp()

def b64(path, mime):
    return 'data:%s;base64,%s' % (mime, base64.b64encode(open(path, 'rb').read()).decode())

def img(rel):
    src = os.path.join(D, rel)
    out = os.path.join(tmp, os.path.basename(rel) + '.jpg')
    subprocess.run(['sips', '-s', 'format', 'jpeg', '-s', 'formatOptions', '82', src, '--out', out],
                   check=True, capture_output=True)
    return b64(out, 'image/jpeg')

s = re.sub(r'url\((fonts/[^)]+\.ttf)\)', lambda m: 'url(%s)' % b64(os.path.join(D, m.group(1)), 'font/ttf'), s)
s = re.sub(r'url\((screens/[^)]+\.png)\)', lambda m: 'url(%s)' % img(m.group(1)), s)
s = re.sub(r'src="(screens/[^"]+\.png)"', lambda m: 'src="%s"' % img(m.group(1)), s)
s = re.sub(r'poster="(media/poster\.png)"', lambda m: 'poster="%s"' % img(m.group(1)), s)
open(os.path.join(D, 'index.html'), 'w', encoding='utf-8').write(s)
print('index.html', round(len(s) / 1e6, 2), 'MB')
