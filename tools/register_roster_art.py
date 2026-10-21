"""Read alpha components and write atlas metadata; never modifies artwork."""
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
NAMES = {1: 'ashigaru', 2: 'yumi_archer', 3: 'hollow_soldier', 4: 'oni_brute',
         5: 'shrine_healer', 6: 'spear_guardian', 7: 'onmyoji', 8: 'hatamoto', 9: 'fallen_daimyo'}


def components(path):
    alpha = np.asarray(Image.open(path).getchannel('A')) > 25
    parents, boxes, sizes, previous = [], [], [], []

    def root(i):
        while parents[i] != i:
            parents[i] = parents[parents[i]]
            i = parents[i]
        return i

    for y, row in enumerate(alpha):
        changes = np.flatnonzero(np.diff(np.pad(row.astype(np.int8), (1, 1))))
        current = []
        for left, right in changes.reshape(-1, 2):
            connected = [root(i) for a, b, i in previous if a <= right + 1 and b >= left - 1]
            if connected:
                index = connected[0]
                for other in connected[1:]:
                    other, index = root(other), root(index)
                    if other != index:
                        parents[other] = index
                        a, b = boxes[index], boxes[other]
                        boxes[index] = [min(a[0], b[0]), min(a[1], b[1]), max(a[2], b[2]), max(a[3], b[3])]
                        sizes[index] += sizes[other]
                box = boxes[index]
                boxes[index] = [min(box[0], left), min(box[1], y), max(box[2], right), y + 1]
                sizes[index] += right - left
            else:
                index = len(parents)
                parents.append(index)
                boxes.append([left, y, right, y + 1])
                sizes.append(right - left)
            current.append((left, right, index))
        previous = current
    main = [(boxes[i], sizes[i]) for i in range(len(parents)) if root(i) == i and sizes[i] > 400]
    return alpha.shape, sorted(main, key=lambda item: item[1], reverse=True)


def register():
    lines = ['class_name RosterAtlasRegions', 'extends RefCounted',
         '## Alpha-component registration. Rebuild with tools/register_roster_art.py.',
         'const REGIONS: Dictionary = {']
    for kind, name in NAMES.items():
        (height, width), shapes = components(ROOT / 'assets/art/roster' / f'{name}.png')
        selected = {}
        for box, area in shapes:
            x, y = (box[0] + box[2]) / (2 * width), (box[1] + box[3]) / (2 * height)
            column = min(range(4), key=lambda col: abs(x - [0.13, 0.38, 0.64, 0.88][col]))
            row = min(range(4), key=lambda r: abs(y - [0.18, 0.435, 0.66, 0.86][r]))
            cell = row * 4 + column
            if cell not in selected:
                selected[cell] = box
        if len(selected) != 16:
            raise ValueError(f'{name}: expected 16 independent components, got {len(selected)}: {selected}')
        lines.append(f'\t{kind}: [ # {name}')
        for cell in range(16):
            left, top, right, bottom = map(int, selected[cell])
            lines.append(f'\t\tRect2({left}, {top}, {right-left}, {bottom-top}),')
        lines.append('\t],')
        print(name, 'registered 16 components')
    lines.append('}')
    (ROOT / 'scripts/visuals/roster_atlas_regions.gd').write_text('\n'.join(lines) + '\n', encoding='utf8')


def register_equipment():
    path = ROOT / 'assets/art/roster/equipment.png'
    (height, width), shapes = components(path)
    selected = {}
    for box, area in shapes:
        x, y = (box[0] + box[2]) / (2 * width), (box[1] + box[3]) / (2 * height)
        col = min(range(4), key=lambda c: abs(x - (c + 0.5) / 4))
        row = min(range(3), key=lambda r: abs(y - [0.17, 0.50, 0.80][r]))
        if row * 4 + col not in selected: selected[row * 4 + col] = box
    if len(selected) != 12: raise ValueError(f'Expected 12 equipment plates: {selected}')
    lines = ['class_name EquipmentAtlasRegions', 'extends RefCounted',
             '## Alpha-component registration; see tools/register_roster_art.py.',
             'const REGIONS: Array[Rect2] = [']
    for cell in range(12):
        x, y, right, bottom = map(int, selected[cell])
        lines.append(f'\tRect2({x}, {y}, {right-x}, {bottom-y}),')
    lines.append(']')
    x, y, right, bottom = map(int, selected[0])
    alpha = np.asarray(Image.open(path).getchannel('A'))
    ys = np.flatnonzero(alpha[y:bottom, int(x + (right-x)*0.2)] > 180)
    top, low = y + int(ys.min()), y + int(ys.max()) + 1
    lines.append(f'const WOOD: Rect2 = Rect2({int(x+(right-x)*0.10)}, {top}, {int((right-x)*0.45)}, {low-top})')
    (ROOT / 'scripts/visuals/equipment_atlas_regions.gd').write_text('\n'.join(lines) + '\n', encoding='utf8')
    print('equipment registered 12 components')


if __name__ == "__main__":
    register()
    if (ROOT / 'assets/art/roster/equipment.png').exists(): register_equipment()
