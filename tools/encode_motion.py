"""Encode untouched Godot renderer frames as a 15 fps animated WebP/GIF (Pillow).

Usage: python tools/encode_motion.py <frame-directory> <output.webp>
This encodes captured playback; it does not animate or repaint a still image.
"""
from pathlib import Path
import sys
from PIL import Image


def main() -> None:
    source, output = map(Path, sys.argv[1:3])
    paths = sorted(source.glob("[0-9][0-9][0-9][0-9].png"))
    if not paths:
        raise SystemExit("No captured frames")
    is_gif = output.suffix.lower() == ".gif"
    with Image.open(paths[0]) as first:
        palette = first.convert("RGB").quantize(colors=256) if is_gif else None
    frames = []
    for path in paths:
        with Image.open(path) as image:
            frame = image.convert("RGB")
            frames.append(frame.quantize(palette=palette, dither=Image.Dither.NONE) if is_gif else frame)
    output.parent.mkdir(parents=True, exist_ok=True)
    durations = [(60 if i % 3 == 0 else 70) if is_gif else (66 if i % 3 == 0 else 67)
                 for i in range(len(frames))]
    options = dict(optimize=False, disposal=1) if is_gif else dict(quality=90, method=4)
    frames[0].save(output, save_all=True, append_images=frames[1:], duration=durations,
                   loop=0, comment=b"Original Godot renderer capture; 60 Hz simulation sampled at 15 fps.", **options)
    print(f"{output}: {len(frames)} captured frames, {sum(durations)/1000:.2f} s, {output.stat().st_size} bytes")


if __name__ == "__main__":
    main()
