#!/usr/bin/env python3
from pathlib import Path
import hashlib, json, subprocess, sys
ROOT=Path(__file__).resolve().parent.parent
subprocess.run([sys.executable,str(ROOT/'tools/build.py')],check=True)
dist=(ROOT/'dist/Archivist_4_4.lua').read_text()
man=json.loads((ROOT/'tools/manifest.json').read_text())
combined=''.join((ROOT / p).read_text() for p in man['sources'])
assert dist.count('local __ARCH_SOURCE = [===[')==1
assert dist.count('local __ARCH_CORE = [===[')==1
assert combined.count('local YSLRuntime = (function()')==1
assert combined.count('local DialogueUtil = {}')==1
assert 'queue_on_teleport' in dist
assert '"@src/ui/esp_preview"' not in combined
assert 'src/ui/14_ui_esp_preview.luau' not in man['sources']
assert 'YSLRuntime.LoadedSignal:fire()' in combined
assert 'loadstring(__ARCH_SOURCE)' in dist
assert 'if not npcTargetPlate then createNPCTargetPlate() end' in combined
assert 'end\ncreateNPCTargetPlate()\n\nlocal currentNPCTarget' not in combined
assert not any(x in dist for x in ['sirius.menu/rayfield','ConfigurationSaving = {'])
print('Static build assertions: PASS')
print('Source segments:',len(man['sources']))
