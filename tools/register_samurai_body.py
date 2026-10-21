"""Read new painted alpha components; preserve the existing rig's joint roles.

This writes GDScript metadata only. It never resizes or modifies the artwork.
"""
from pathlib import Path
import numpy as np
from PIL import Image
from register_roster_art import components

ROOT = Path(__file__).resolve().parents[1]
SHEETS = {
    'body_trunk': ['torso', 'skirt', 'mane', 'sash'],
    'body_arms': ['upper_f', 'fore_f', 'upper_b', 'fore_b'],
    'body_legs': ['thigh_f', 'shin_f', 'thigh_b', 'shin_b'],
    'body_details': ['foot_f', 'foot_b', 'sleeve_f', 'sleeve_b'],
}
# Normalized joint positions retain the artist's original component orientation.
ANCHORS = {
    'upper_f': ((22/261, 42/225), (230/261, 87/225), 13, 10.55),
    'fore_f': ((26/277, 54/166), (242/277, 110/166), 13, 6.33),
    'upper_b': ((35/288, 55/250), (245/288, 93/250), 13, 11.45),
    'fore_b': ((28/280, 53/154), (240/280, 100/154), 13, 5.22),
    'thigh_f': ((39/303, 60/257), (264/303, 170/257), 23, 20.5),
    'shin_f': ((29/260, 65/150), (230/260, 93/150), 23, 11.4),
    'thigh_b': ((35/300, 95/255), (266/300, 155/255), 23, 20.9),
    'shin_b': ((32/240, 95/170), (225/240, 60/170), 23, 13.7),
}


def main():
    regions, joints = {}, {}
    for sheet, names in SHEETS.items():
        path = ROOT / 'assets/art/samurai' / f'{sheet}.png'
        (height, width), shapes = components(path)
        selected = {}
        for box, area in shapes:
            cx, cy = (box[0]+box[2])/(2*width), (box[1]+box[3])/(2*height)
            cell = (2 if cy > .5 else 0) + (1 if cx > .5 else 0)
            if cell not in selected: selected[cell] = box
        if len(selected) != 4: raise ValueError(f'{sheet}: expected four components: {selected}')
        alpha = np.asarray(Image.open(path).getchannel('A'))
        for cell, name in enumerate(names):
            x,y,right,bottom = map(int, selected[cell]); w,h=right-x,bottom-y
            regions[name]=(x,y,w,h)
            if name in ANCHORS:
                ua,ub,length,target_width=ANCHORS[name]
                a=np.asarray(ua)*[w,h]; b=np.asarray(ub)*[w,h]
                axis=(b-a)/np.linalg.norm(b-a)
                yy,xx=np.nonzero(alpha[y:bottom,x:right]>25)
                cross=-(xx-a[0])*axis[1]+(yy-a[1])*axis[0]
                scale=target_width/float(cross.max()-cross.min())
                joints[name]=(a,b,length,scale)
        print(sheet, f'{width}x{height}', ', '.join(f'{n}:{regions[n][2]}x{regions[n][3]}' for n in names))
    # Isolated horizontal flow plates keep neighbouring skirt/hair pixels out
    # of deforming UV ribbons; the trunk sheet still supplies torso and skirt.
    flow_path = ROOT / 'assets/art/samurai/body_flow.png'
    _, flow_shapes = components(flow_path)
    flow = sorted(flow_shapes[:2], key=lambda item: item[0][1])
    if len(flow) != 2: raise ValueError('Expected separate hair and sash plates')
    for name, (box, _) in zip(['mane', 'sash'], flow):
        x,y,right,bottom=map(int,box); regions[name]=(x,y,right-x,bottom-y)
    regions.update(head=(239,158,952,979), weapon=(936,1047,309,62))
    lines=['class_name SamuraiBodyLayout','extends RefCounted',
           '## Original painted layers; rebuild registration with tools/register_samurai_body.py.',
           'const SOURCES: Dictionary = {']
    for name,box in regions.items(): lines.append(f'\t&"{name}": Rect2({", ".join(map(str,box))}),')
    lines.extend(['}', 'const JOINTS: Dictionary = {'])
    for name,(a,b,length,scale) in joints.items():
        lines.append(f'\t&"{name}": [Vector2({a[0]:.5f}, {a[1]:.5f}), Vector2({b[0]:.5f}, {b[1]:.5f}), {length}.0, {scale:.8f}],')
    lines.append('}')
    (ROOT / 'scripts/visuals/samurai_body_layout.gd').write_text('\n'.join(lines)+'\n', encoding='utf8')


if __name__ == '__main__': main()
