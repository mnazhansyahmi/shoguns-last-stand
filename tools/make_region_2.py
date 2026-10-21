"""Writes the Region 2 "Burning Village" resources: stages 6-10 with their waves, their atmosphere themes and the
region file.

Run from the project root:  python tools/make_region_2.py
Edit the STAGES / THEMES tables below and re-run to retune; then run godot_console --headless --import so the
resources are re-imported. Stage ids are save keys: never rename them. (Region 1 has its own script,
tools/make_region_1.py; this one never touches Region 1's files.)
"""
import os

# Enemy keys used in the wave tables -> resource path.
ENEMIES = {
    "H": "res://data/enemies/hollow_soldier.tres",
    "O": "res://data/enemies/oni_brute.tres",
}

# Each wave: list of entries (enemy key, count, start_delay, spawn_interval).
STAGES = [
    {
        "number": 6, "name": "Ember Road", "bonus_gold": 1000, "bonus_xp": 170, "break": 6.0, "theme": "village_dusk",
        "description": "The road into the village is lit by burning houses. The Hollow host marches through the smoke.",
        "tagline": "Smoke on the village road",
        "waves": [
            [("H", 18, 0.0, 0.4)],
            [("H", 16, 0.0, 0.4), ("O", 2, 1.0, 2.5)],
            [("H", 20, 0.0, 0.35), ("O", 3, 0.5, 2.5)],
            [("H", 18, 0.0, 0.35), ("O", 3, 0.5, 2.0)],
            [("H", 20, 0.0, 0.35), ("O", 4, 0.5, 2.0)],
        ],
    },
    {
        "number": 7, "name": "Ashen Fields", "bonus_gold": 1120, "bonus_xp": 190, "break": 6.0, "theme": "ashen_fields",
        "description": "Rice fields under falling ash. Arrows come out of the smoke: keep your allies covered.",
        "tagline": "Arrows from the smoke",
        "waves": [
            [("H", 20, 0.0, 0.4)],
            [("H", 18, 0.0, 0.35), ("O", 3, 1.0, 2.5)],
            [("H", 20, 0.0, 0.35), ("O", 3, 0.5, 2.5)],
            [("H", 20, 0.0, 0.35), ("O", 4, 0.5, 2.0)],
            [("H", 22, 0.0, 0.33), ("O", 4, 0.5, 2.0)],
        ],
    },
    {
        "number": 8, "name": "Burning Market", "bonus_gold": 1240, "bonus_xp": 210, "break": 6.5, "theme": "burning_market",
        "description": "The market street is ablaze. Shields lock in front of the soldiers: break them with heavy blows or strike from behind.",
        "tagline": "Shields in the market",
        "waves": [
            [("H", 20, 0.0, 0.35)],
            [("H", 18, 0.0, 0.35), ("O", 3, 1.0, 2.5)],
            [("H", 22, 0.0, 0.33), ("O", 4, 0.5, 2.0)],
            [("H", 20, 0.0, 0.33), ("O", 4, 0.5, 2.0)],
            [("H", 24, 0.0, 0.33), ("O", 5, 0.5, 2.0)],
        ],
    },
    {
        "number": 9, "name": "Smoke Shrine", "bonus_gold": 1360, "bonus_xp": 230, "break": 6.5, "theme": "smoke_shrine",
        "description": "The village shrine burns and its spirits fly free. Only the Bow, archers and the Onmyoji can reach them.",
        "tagline": "Spirits in the smoke",
        "waves": [
            [("H", 22, 0.0, 0.35)],
            [("H", 20, 0.0, 0.33), ("O", 3, 1.0, 2.5)],
            [("H", 22, 0.0, 0.33), ("O", 4, 0.5, 2.0)],
            [("H", 22, 0.0, 0.3), ("O", 5, 0.5, 2.0)],
            [("H", 24, 0.0, 0.3), ("O", 5, 0.5, 2.0)],
        ],
    },
    {
        "number": 10, "name": "The Burning Keep", "bonus_gold": 2000, "bonus_xp": 320, "break": 7.0, "theme": "burning_keep",
        "description": "The headman's keep at the heart of the fire. Hold the gate against the whole host.",
        "tagline": "The heart of the fire",
        "waves": [
            [("H", 22, 0.0, 0.33)],
            [("H", 20, 0.0, 0.3), ("O", 4, 1.0, 2.0)],
            [("H", 24, 0.0, 0.3), ("O", 4, 0.5, 2.0)],
            [("H", 22, 0.0, 0.3), ("O", 5, 0.5, 2.0)],
            [("O", 7, 0.0, 2.0), ("H", 16, 2.0, 0.4)],
        ],
    },
]

# Burning-village dusk themes, darker, redder and more on fire stage by stage.
BASE_THEME = {
    "sun_radius": 88.0, "eclipse": False, "cloud_alpha": 0.8,
    "wind_base": 0.45, "wind_gust": 0.5, "petal_share": 0.05,
    "petal_color": "#f0b8a0", "fire_core": "#ffe08a", "fire_glow": "#ff7a2a",
}
THEMES = {
    "village_dusk": {
        "display_name": "Village at Dusk", "fire_intensity": 0.35, "ember_share": 0.45,
        "sky_top": "#2b2240", "sky_mid": "#8a3a3a", "sky_low": "#e07a3a", "sky_horizon": "#f4b066",
        "sun_core": "#ffd890", "sun_halo": "#ff9a4a", "cloud_lit": "#ff9850", "cloud_shadow": "#5a3040",
        "mountain_far": "#c08a84", "mountain_mid": "#a87478", "mist": "#e8b090",
        "ground_top": "#c4987e", "ground_bottom": "#2a1e26", "bamboo_far": "#b08478", "bamboo_near": "#3a2a30",
        "ray_color": "#ffb060", "rim_color": "#ffb468", "reed_stalk": "#d09a62", "reed_plume": "#f2d0a0",
        "leaf_colors": ["#d24a1e", "#e8702a", "#b83a1a"], "smoke": "#4a3640",
    },
    "ashen_fields": {
        "display_name": "Ashen Fields", "fire_intensity": 0.5, "ember_share": 0.5, "wind_base": 0.4, "cloud_alpha": 0.9,
        "sky_top": "#3a2c3a", "sky_mid": "#9a5a48", "sky_low": "#d0905e", "sky_horizon": "#e8b884",
        "sun_core": "#ffe2b0", "sun_halo": "#f0a060", "cloud_lit": "#e8a070", "cloud_shadow": "#4e3a44",
        "mountain_far": "#b8968e", "mountain_mid": "#a08280", "mist": "#e2bea4",
        "ground_top": "#c2a28a", "ground_bottom": "#2a2226", "bamboo_far": "#aa8a80", "bamboo_near": "#383034",
        "ray_color": "#f0b070", "rim_color": "#f4b878", "reed_stalk": "#c8a070", "reed_plume": "#eed4b0",
        "leaf_colors": ["#c85a2a", "#a8a0a0", "#e0803a"], "smoke": "#504448",
    },
    "burning_market": {
        "display_name": "Burning Market", "fire_intensity": 0.7, "ember_share": 0.6, "wind_base": 0.5,
        "sky_top": "#2a1630", "sky_mid": "#a62e2a", "sky_low": "#f06a2a", "sky_horizon": "#ffa850",
        "sun_core": "#ffe08a", "sun_halo": "#ff7a34", "cloud_lit": "#ff7a3a", "cloud_shadow": "#4a2232",
        "mountain_far": "#c87a70", "mountain_mid": "#b06464", "mist": "#f0a880",
        "ground_top": "#c88e72", "ground_bottom": "#28181e", "bamboo_far": "#b87a6c", "bamboo_near": "#36222a",
        "ray_color": "#ff9a4a", "rim_color": "#ffa058", "reed_stalk": "#d8905a", "reed_plume": "#f6c898",
        "leaf_colors": ["#e04a1a", "#ff7a2a", "#c0301a"], "smoke": "#42282e",
    },
    "smoke_shrine": {
        "display_name": "Smoke Shrine", "fire_intensity": 0.8, "ember_share": 0.55, "wind_base": 0.35, "wind_gust": 0.4,
        "sky_top": "#1e1a34", "sky_mid": "#6a2e4a", "sky_low": "#c8603e", "sky_horizon": "#e8a070",
        "sun_core": "#f6d2a0", "sun_halo": "#e8784a", "cloud_lit": "#e8784a", "cloud_shadow": "#3a2440",
        "mountain_far": "#b08088", "mountain_mid": "#9a6c7a", "mist": "#deaa96",
        "ground_top": "#b88e80", "ground_bottom": "#221a26", "bamboo_far": "#a87c80", "bamboo_near": "#30242e",
        "ray_color": "#f09a62", "rim_color": "#f4a070", "reed_stalk": "#c08a6a", "reed_plume": "#ecc8ac",
        "leaf_colors": ["#c83a2a", "#e86a3a", "#a82a2a"], "smoke": "#3a2a36",
    },
    "burning_keep": {
        "display_name": "The Burning Keep", "fire_intensity": 1.0, "ember_share": 0.7, "wind_base": 0.6, "wind_gust": 0.55,
        "eclipse": True, "sun_radius": 104.0,
        "sky_top": "#160e1e", "sky_mid": "#7a1a1e", "sky_low": "#e0501e", "sky_horizon": "#ff9a3e",
        "sun_core": "#1a0c12", "sun_halo": "#ff6a22", "cloud_lit": "#ff6026", "cloud_shadow": "#2e121e",
        "mountain_far": "#c06a5c", "mountain_mid": "#a85a56", "mist": "#ee9c74",
        "ground_top": "#c4846a", "ground_bottom": "#20121a", "bamboo_far": "#b46e60", "bamboo_near": "#301a22",
        "ray_color": "#ff8a3a", "rim_color": "#ff9248", "reed_stalk": "#d47e4e", "reed_plume": "#f4bc8c",
        "leaf_colors": ["#ff5a1a", "#ff8a2a", "#e03a1a"], "smoke": "#341c22",
    },
}

INK = "#121018"


def _rgb(hex_color):
    h = hex_color.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def _luminance(hex_color):
    def channel(c):
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (channel(c) for c in _rgb(hex_color))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def _contrast(a, b):
    la, lb = _luminance(a), _luminance(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)


def check_theme(theme_id, theme):
    """The art bible's contrast rules (the same as AtmosphereTheme.action_band_colors() and its test)."""
    rules = [("sky_low", 3.0), ("sky_horizon", 3.0), ("mountain_far", 3.0), ("mountain_mid", 3.0), ("bamboo_far", 3.0),
             ("reed_stalk", 3.0), ("mist", 4.5), ("ground_top", 4.5), ("rim_color", 3.0), ("reed_plume", 3.0)]
    for key, ratio in rules:
        got = _contrast(INK, theme[key])
        assert got >= ratio, "%s: %s vs ink %.2f < %.1f" % (theme_id, key, got, ratio)
    for leaf in theme["leaf_colors"]:
        assert _contrast(INK, leaf) >= 2.0, "%s: leaf %s too dark" % (theme_id, leaf)
    assert _luminance(theme["sky_top"]) < _luminance(theme["sky_low"]) <= _luminance(theme["sky_horizon"]) + 0.001, theme_id


def _color(hex_color):
    r, g, b = _rgb(hex_color)
    return "Color(%.4f, %.4f, %.4f, 1)" % (r, g, b)


def theme_tres(theme_id, values):
    theme = dict(BASE_THEME)
    theme.update(values)
    check_theme(theme_id, theme)
    colors = ["sky_top", "sky_mid", "sky_low", "sky_horizon", "sun_core", "sun_halo", "cloud_lit", "cloud_shadow",
              "mountain_far", "mountain_mid", "mist", "ground_top", "ground_bottom", "bamboo_far", "bamboo_near",
              "ray_color", "rim_color", "reed_stalk", "reed_plume", "petal_color", "fire_core", "fire_glow", "smoke"]
    lines = ['[gd_resource type="Resource" script_class="AtmosphereTheme" format=3]', "",
             '[ext_resource type="Script" path="res://scripts/resources/atmosphere_theme.gd" id="1_theme"]', "",
             "[resource]", 'script = ExtResource("1_theme")',
             'theme_id = "%s"' % theme_id, 'display_name = "%s"' % theme["display_name"], "scenery = 1"]
    for key in colors:
        lines.append("%s = %s" % (key, _color(theme[key])))
    leaves = ", ".join("%.4f, %.4f, %.4f, 1" % _rgb(c) for c in theme["leaf_colors"])
    lines += ["leaf_colors = PackedColorArray(%s)" % leaves,
              "sun_radius = %s" % float(theme["sun_radius"]), "eclipse = %s" % ("true" if theme["eclipse"] else "false"),
              "cloud_alpha = %s" % theme["cloud_alpha"], "wind_base = %s" % theme["wind_base"],
              "wind_gust = %s" % theme["wind_gust"], "petal_share = %s" % theme["petal_share"],
              "fire_intensity = %s" % theme["fire_intensity"], "ember_share = %s" % theme["ember_share"], ""]
    return "\n".join(lines)


def wave_tres(entries):
    keys = []
    for entry in entries:
        if entry[0] not in keys:
            keys.append(entry[0])
    lines = ['[gd_resource type="Resource" script_class="WaveData" format=3]', "",
             '[ext_resource type="Script" path="res://scripts/resources/wave_data.gd" id="1_wave"]',
             '[ext_resource type="Script" path="res://scripts/resources/wave_entry.gd" id="2_entry"]']
    for key in keys:
        lines.append('[ext_resource type="Resource" path="%s" id="e_%s"]' % (ENEMIES[key], key))
    lines.append("")
    ids = []
    for n, (key, count, delay, interval) in enumerate(entries):
        sub_id = "Entry_%d" % (n + 1)
        ids.append(sub_id)
        lines += ['[sub_resource type="Resource" id="%s"]' % sub_id, 'script = ExtResource("2_entry")',
                  'enemy = ExtResource("e_%s")' % key,
                  "count = %d" % count, "start_delay = %s" % float(delay), "spawn_interval = %s" % float(interval), ""]
    lines += ["[resource]", 'script = ExtResource("1_wave")',
              "entries = Array[ExtResource(\"2_entry\")]([%s])" % ", ".join('SubResource("%s")' % i for i in ids), ""]
    return "\n".join(lines)


def stage_tres(stage, wave_paths):
    lines = ['[gd_resource type="Resource" script_class="StageData" format=3]', "",
             '[ext_resource type="Script" path="res://scripts/resources/stage_data.gd" id="1_stage"]',
             '[ext_resource type="Script" path="res://scripts/resources/wave_data.gd" id="2_wave"]',
             '[ext_resource type="Resource" path="res://data/atmosphere/%s.tres" id="atmo"]' % stage["theme"]]
    for n, path in enumerate(wave_paths):
        lines.append('[ext_resource type="Resource" path="%s" id="w%d"]' % (path, n + 1))
    lines += ["", "[resource]", 'script = ExtResource("1_stage")',
              'stage_id = "stage_%d"' % stage["number"],
              'display_name = "%s"' % stage["name"],
              "waves = Array[ExtResource(\"2_wave\")]([%s])" % ", ".join('ExtResource("w%d")' % (n + 1) for n in range(len(wave_paths))),
              "first_wave_delay = 4.0", "break_duration = %s" % stage["break"],
              "clear_gold_bonus = %d" % stage["bonus_gold"], "clear_xp_bonus = %d" % stage["bonus_xp"],
              "defeat_reward_ratio = 0.5", "replay_gold_multiplier = 0.5",
              'atmosphere = ExtResource("atmo")',
              'description = "%s"' % stage["description"],
              'tagline = "%s"' % stage["tagline"], ""]
    return "\n".join(lines)


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def main():
    for theme_id, values in THEMES.items():
        write("data/atmosphere/%s.tres" % theme_id, theme_tres(theme_id, values))
    for stage in STAGES:
        folder = "data/stages/stage_%d" % stage["number"]
        # Drop waves left over from a longer earlier version of the table.
        if os.path.isdir(folder):
            for name in os.listdir(folder):
                if name.startswith("wave_") and name.endswith(".tres"):
                    os.remove(os.path.join(folder, name))
        wave_paths = []
        for n, entries in enumerate(stage["waves"]):
            path = "%s/wave_%d.tres" % (folder, n + 1)
            write(path, wave_tres(entries))
            wave_paths.append("res://" + path)
        write("data/stages/stage_%d.tres" % stage["number"], stage_tres(stage, wave_paths))
        totals = {key: sum(e[1] for w in stage["waves"] for e in w if e[0] == key) for key in ENEMIES}
        print("stage_%-2d %-17s waves %d  %s" % (stage["number"], stage["name"], len(stage["waves"]),
                                                  "  ".join("%s %3d" % (k, v) for k, v in totals.items() if v)))

    region = ['[gd_resource type="Resource" script_class="RegionData" format=3]', "",
              '[ext_resource type="Script" path="res://scripts/resources/region_data.gd" id="1_region"]',
              '[ext_resource type="Script" path="res://scripts/resources/stage_data.gd" id="2_stage"]']
    numbers = [stage["number"] for stage in STAGES]
    for n in numbers:
        region.append('[ext_resource type="Resource" path="res://data/stages/stage_%d.tres" id="s%d"]' % (n, n))
    region += ["", "[resource]", 'script = ExtResource("1_region")', 'region_id = "burning_village"',
               'display_name = "Burning Village"',
               "stages = Array[ExtResource(\"2_stage\")]([%s])" % ", ".join('ExtResource("s%d")' % n for n in numbers), ""]
    write("data/regions/burning_village.tres", "\n".join(region))
    print("wrote data/regions/burning_village.tres")


if __name__ == "__main__":
    main()
