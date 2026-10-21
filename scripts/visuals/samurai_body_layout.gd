class_name SamuraiBodyLayout
extends RefCounted
## Original painted layers; rebuild registration with tools/register_samurai_body.py.
const SOURCES: Dictionary = {
	&"torso": Rect2(32, 96, 636, 652),
	&"skirt": Rect2(677, 115, 555, 711),
	&"mane": Rect2(43, 43, 1457, 547),
	&"sash": Rect2(87, 589, 1400, 405),
	&"upper_f": Rect2(26, 131, 590, 507),
	&"fore_f": Rect2(633, 250, 610, 387),
	&"upper_b": Rect2(28, 666, 600, 502),
	&"fore_b": Rect2(660, 784, 578, 351),
	&"thigh_f": Rect2(47, 47, 734, 478),
	&"shin_f": Rect2(831, 171, 648, 348),
	&"thigh_b": Rect2(49, 511, 743, 483),
	&"shin_b": Rect2(861, 625, 611, 363),
	&"foot_f": Rect2(64, 80, 540, 464),
	&"foot_b": Rect2(674, 76, 553, 461),
	&"sleeve_f": Rect2(42, 619, 596, 581),
	&"sleeve_b": Rect2(678, 624, 541, 613),
	&"head": Rect2(239, 158, 952, 979),
	&"weapon": Rect2(936, 1047, 309, 62),
}
const JOINTS: Dictionary = {
	&"upper_f": [Vector2(49.73180, 94.64000), Vector2(519.92337, 196.04000), 13.0, 0.02515137],
	&"fore_f": [Vector2(57.25632, 125.89157), Vector2(532.92419, 256.44578), 13.0, 0.02012497],
	&"upper_b": [Vector2(72.91667, 110.44000), Vector2(510.41667, 186.74400), 13.0, 0.02663638],
	&"fore_b": [Vector2(57.80000, 120.79870), Vector2(495.42857, 227.92208), 13.0, 0.01762234],
	&"thigh_f": [Vector2(94.47525, 111.59533), Vector2(639.52475, 316.18677), 23.0, 0.04114671],
	&"shin_f": [Vector2(72.27692, 150.80000), Vector2(573.23077, 215.76000), 23.0, 0.03851974],
	&"thigh_b": [Vector2(86.68333, 179.94118), Vector2(658.79333, 293.58824), 23.0, 0.04088853],
	&"shin_b": [Vector2(81.46667, 202.85294), Vector2(572.81250, 128.11765), 23.0, 0.03235354],
}
