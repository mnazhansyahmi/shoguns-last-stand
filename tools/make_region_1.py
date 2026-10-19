"""Writes the Region 1 "Bamboo Outskirts" stage resources (stages 2-5 + region file).

Run from the project root:  python tools/make_region_1.py
Stage 1 (data/stages/stage_1.tres and its waves) is hand-tuned and left untouched apart from its
description/replay fields. Edit the STAGES table below and re-run to retune; then open Godot (or run
godot_console --headless --import) so the resources are re-imported.
"""
import os

HOLLOW = "res://data/enemies/hollow_soldier.tres"
ONI = "res://data/enemies/oni_brute.tres"

# Each wave: list of entries (enemy, count, start_delay, spawn_interval).
STAGES = [
    {
        "number": 2, "name": "Bamboo Path", "bonus_gold": 200, "bonus_xp": 70, "break": 5.0,
        "description": "Soldiers slip through the bamboo in longer lines. One Oni Brute.",
        "waves": [
            [("H", 8, 0.0, 0.8)],
            [("H", 10, 0.0, 0.7)],
            [("H", 8, 0.0, 0.6), ("O", 1, 1.5, 0.0)],
            [("H", 12, 0.0, 0.55)],
        ],
    },
    {
        "number": 3, "name": "Misty Grove", "bonus_gold": 260, "bonus_xp": 90, "break": 5.0,
        "description": "Thick mist and faster packs. Oni Brutes start heading for the gate.",
        "waves": [
            [("H", 10, 0.0, 0.6)],
            [("H", 10, 0.0, 0.55), ("O", 1, 1.0, 0.0)],
            [("H", 12, 0.0, 0.5), ("O", 2, 1.0, 3.0)],
            [("H", 12, 0.0, 0.5), ("O", 2, 0.5, 3.0)],
        ],
    },
    {
        "number": 4, "name": "Broken Shrine", "bonus_gold": 330, "bonus_xp": 110, "break": 6.0,
        "description": "Five waves around the ruined shrine. The Oni come in pairs and threes.",
        "waves": [
            [("H", 14, 0.0, 0.5)],
            [("H", 12, 0.0, 0.45), ("O", 2, 1.0, 3.0)],
            [("H", 16, 0.0, 0.45), ("O", 2, 0.5, 2.5)],
            [("H", 14, 0.0, 0.4), ("O", 3, 0.5, 2.5)],
            [("H", 16, 0.0, 0.4), ("O", 3, 0.5, 2.0)],
        ],
    },
    {
        "number": 5, "name": "Oni's Hollow", "bonus_gold": 450, "bonus_xp": 150, "break": 6.0,
        "description": "The Oni's lair. Survive the swarm, then the boss wave of Oni Brutes.",
        "waves": [
            [("H", 16, 0.0, 0.45)],
            [("H", 14, 0.0, 0.4), ("O", 3, 1.0, 2.5)],
            [("H", 18, 0.0, 0.4), ("O", 3, 0.5, 2.5)],
            [("H", 16, 0.0, 0.35), ("O", 4, 0.5, 2.0)],
            # Boss wave: a line of Oni Brutes with soldiers pouring in behind them.
            [("O", 6, 0.0, 2.0), ("H", 12, 2.0, 0.5)],
        ],
    },
]


def wave_tres(entries):
    uses_h = any(e[0] == "H" for e in entries)
    uses_o = any(e[0] == "O" for e in entries)
    lines = ['[gd_resource type="Resource" script_class="WaveData" format=3]', "",
             '[ext_resource type="Script" path="res://scripts/resources/wave_data.gd" id="1_wave"]',
             '[ext_resource type="Script" path="res://scripts/resources/wave_entry.gd" id="2_entry"]']
    if uses_h:
        lines.append('[ext_resource type="Resource" path="%s" id="3_hollow"]' % HOLLOW)
    if uses_o:
        lines.append('[ext_resource type="Resource" path="%s" id="4_oni"]' % ONI)
    lines.append("")
    ids = []
    for n, (kind, count, delay, interval) in enumerate(entries):
        sub_id = "Entry_%d" % (n + 1)
        ids.append(sub_id)
        lines += ['[sub_resource type="Resource" id="%s"]' % sub_id, 'script = ExtResource("2_entry")',
                  'enemy = ExtResource("%s")' % ("3_hollow" if kind == "H" else "4_oni"),
                  "count = %d" % count, "start_delay = %s" % float(delay), "spawn_interval = %s" % float(interval), ""]
    lines += ["[resource]", 'script = ExtResource("1_wave")',
              "entries = Array[ExtResource(\"2_entry\")]([%s])" % ", ".join('SubResource("%s")' % i for i in ids), ""]
    return "\n".join(lines)


def stage_tres(stage, wave_paths):
    lines = ['[gd_resource type="Resource" script_class="StageData" format=3]', "",
             '[ext_resource type="Script" path="res://scripts/resources/stage_data.gd" id="1_stage"]',
             '[ext_resource type="Script" path="res://scripts/resources/wave_data.gd" id="2_wave"]']
    for n, path in enumerate(wave_paths):
        lines.append('[ext_resource type="Resource" path="%s" id="w%d"]' % (path, n + 1))
    lines += ["", "[resource]", 'script = ExtResource("1_stage")',
              'stage_id = "stage_%d"' % stage["number"],
              'display_name = "%s"' % stage["name"],
              "waves = Array[ExtResource(\"2_wave\")]([%s])" % ", ".join('ExtResource("w%d")' % (n + 1) for n in range(len(wave_paths))),
              "first_wave_delay = 3.0", "break_duration = %s" % stage["break"],
              "clear_gold_bonus = %d" % stage["bonus_gold"], "clear_xp_bonus = %d" % stage["bonus_xp"],
              "defeat_reward_ratio = 0.5", "replay_gold_multiplier = 0.5",
              'description = "%s"' % stage["description"], ""]
    return "\n".join(lines)


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def main():
    for stage in STAGES:
        folder = "data/stages/stage_%d" % stage["number"]
        wave_paths = []
        for n, entries in enumerate(stage["waves"]):
            path = "%s/wave_%d.tres" % (folder, n + 1)
            write(path, wave_tres(entries))
            wave_paths.append("res://" + path)
        write("data/stages/stage_%d.tres" % stage["number"], stage_tres(stage, wave_paths))
        total_h = sum(e[1] for w in stage["waves"] for e in w if e[0] == "H")
        total_o = sum(e[1] for w in stage["waves"] for e in w if e[0] == "O")
        print("stage_%d %-14s waves %d  soldiers %3d  oni %2d" % (stage["number"], stage["name"], len(stage["waves"]), total_h, total_o))

    region = ['[gd_resource type="Resource" script_class="RegionData" format=3]', "",
              '[ext_resource type="Script" path="res://scripts/resources/region_data.gd" id="1_region"]',
              '[ext_resource type="Script" path="res://scripts/resources/stage_data.gd" id="2_stage"]']
    for n in range(1, 6):
        region.append('[ext_resource type="Resource" path="res://data/stages/stage_%d.tres" id="s%d"]' % (n, n))
    region += ["", "[resource]", 'script = ExtResource("1_region")', 'region_id = "bamboo_outskirts"',
               'display_name = "Bamboo Outskirts"',
               "stages = Array[ExtResource(\"2_stage\")]([%s])" % ", ".join('ExtResource("s%d")' % n for n in range(1, 6)), ""]
    write("data/regions/bamboo_outskirts.tres", "\n".join(region))
    print("wrote data/regions/bamboo_outskirts.tres")


if __name__ == "__main__":
    main()
