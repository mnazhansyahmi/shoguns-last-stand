"""Encode actual Godot captures as compact review clips (no source-art processing)."""
from pathlib import Path
import sys
from PIL import Image

ROOT = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parents[1] / 'docs/combat_polish/part3'
for name in ('fallen_daimyo', 'burning_general'):
    folder = ROOT / name
    files = sorted(folder.glob('frame_*.png'))
    frames = []
    for path in files:
        with Image.open(path) as source:
            frames.append(source.convert('RGB').resize((960, 540), Image.Resampling.LANCZOS))
    frames[0].save(ROOT / f'{name}_motion.webp', save_all=True,
                   append_images=frames[1:], duration=100, loop=0, quality=80, method=4)
    for number, label in ((3, 'entrance'), (32, 'motion'), (50, 'recovery')):
        (ROOT / f'{name}_{label}.png').write_bytes(files[number].read_bytes())
    print(name, len(frames), 'captured frames, 6 seconds')
