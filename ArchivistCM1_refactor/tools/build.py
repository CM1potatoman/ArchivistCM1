#!/usr/bin/env python3
"""Deterministic Archivist 4.4 source bundler.

Modules under src/app are ordered Luau compilation units/fragments. They share
locals when assembled; never load them individually with loadstring. Modules
under src/ui are sections of the embedded YSL module table.
"""
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

def build():
    data=json.loads((ROOT/'tools/manifest.json').read_text())
    source=''.join((ROOT / path).read_text(encoding='utf-8') for path in data['sources'])
    core=(ROOT/'src/runtime/teleport_launcher.luau').read_text(encoding='utf-8')
    prefix=(ROOT/'tools/wrapper-prefix.txt').read_text(encoding='utf-8')
    middle=(ROOT/'tools/wrapper-middle.txt').read_text(encoding='utf-8')
    suffix=(ROOT/'tools/wrapper-suffix.txt').read_text(encoding='utf-8')
    assert middle.startswith(']===]\nlocal __ARCH_HANDOFF')
    assert suffix.startswith(']===]\nlocal __ARCH_FACTORY')
    # Detect bracket delimiter collisions before generating loader strings.
    assert ']===]' not in source and ']===]' not in core
    output=prefix+source+middle+core+suffix
    dest=ROOT/'dist/Archivist_4_4.lua'
    dest.parent.mkdir(exist_ok=True)
    dest.write_text(output,encoding='utf-8')
    return dest,source,core

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--check',action='store_true',help='Compare against untouched original when possible')
    args=parser.parse_args()
    dest,source,core=build()
    sha=hashlib.sha256(dest.read_bytes()).hexdigest()
    print(f'Built {dest.relative_to(ROOT)}: {len(dest.read_bytes()):,} bytes, {len(dest.read_text().splitlines()):,} lines')
    print('SHA-256:',sha)
    if args.check:
        reference=(ROOT/'tools/reference.sha256').read_text().split()[0]
        if reference!=sha:
            raise SystemExit('Build differs from the unmodified reference (expected if optimizations applied)')
        print('Exact roundtrip PASS')
