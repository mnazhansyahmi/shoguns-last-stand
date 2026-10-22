"""Read-only pixel validation of fixed-time rendered menu frames (Pillow/numpy)."""
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / "docs/world_polish/part3"
data = json.loads((FOLDER / "menu_transform.json").read_text())
base = np.asarray(Image.open(FOLDER / "menu_t000.png").convert("RGB"), dtype=np.int16)
alpha = np.asarray(Image.open(ROOT / "assets/art/world/menu_character.png"))[:, :, 3]
y, x = np.indices(base.shape[:2])
x = x * data["logical_size"][0] / base.shape[1]
y = y * data["logical_size"][1] / base.shape[0]
sx = ((x - data["scene_position"][0]) / data["scene_scale"] - data["character_offset"][0]) / data["character_scale"][0]
sy = ((y - data["scene_position"][1]) / data["scene_scale"] - data["character_offset"][1]) / data["character_scale"][1]
inside = (sx >= 0) & (sx < alpha.shape[1]) & (sy >= 0) & (sy < alpha.shape[0])
mask = inside & (alpha[sy.clip(0, alpha.shape[0] - 1).astype(int), sx.clip(0, alpha.shape[1] - 1).astype(int)] > 3)
# Conservative 20 screen-pixel allowance for the moving tips and filtering.
envelope = np.asarray(Image.fromarray(mask.astype("uint8") * 255).filter(ImageFilter.MaxFilter(41))) > 0
results = {}
for name in ["menu_t010", "menu_t020", "menu_t040", "menu_t113", "menu_t140"]:
    frame = np.asarray(Image.open(FOLDER / (name + ".png")).convert("RGB"), dtype=np.int16)
    changed = np.max(np.abs(frame - base), axis=2) > 0
    results[name] = {"changed_character_pixels": int((changed & envelope).sum()),
                     "changed_background_pixels": int((changed & ~envelope).sum())}
normal = np.abs(np.asarray(Image.open(FOLDER / "menu_t020.png").convert("RGB"), dtype=np.int16) - base)
reduced_a = np.asarray(Image.open(FOLDER / "menu_reduced_t000.png").convert("RGB"), dtype=np.int16)
reduced_b = np.asarray(Image.open(FOLDER / "menu_reduced_t020.png").convert("RGB"), dtype=np.int16)
results["motion_pixel_difference_sum"] = {"normal": int(normal.sum()), "reduced": int(np.abs(reduced_b - reduced_a).sum())}
print(json.dumps(results, indent=2))
assert all(value["changed_background_pixels"] == 0 for name, value in results.items() if name.startswith("menu_t"))
assert results["motion_pixel_difference_sum"]["reduced"] < results["motion_pixel_difference_sum"]["normal"]
