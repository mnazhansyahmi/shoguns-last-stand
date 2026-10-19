class_name InkPalette
extends RefCounted
## The game's colours in one place. docs/ART_BIBLE.md documents every value; keep them in sync.

# --- Ink -------------------------------------------------------------------
const INK: Color = Color("#121018")
const INK_BACK: Color = Color("#2a2633")
const INK_DETAIL: Color = Color("#3b3646")
const PAPER: Color = Color("#efe6cf")
const STEEL: Color = Color("#c9ced6")

# --- Character accents (one per character) ---------------------------------
const SAMURAI_RED: Color = Color("#d7372b")
const ASHIGARU_GOLD: Color = Color("#e2b23e")
const ARCHER_TEAL: Color = Color("#2bb3a3")
const HOLLOW_PURPLE: Color = Color("#b56cff")
const ONI_EMBER: Color = Color("#d8281e")
const HEALER_JADE: Color = Color("#5fd4a0")
const GUARDIAN_AZURE: Color = Color("#4f86e0")
const ONMYOJI_MAGENTA: Color = Color("#d65db1")
const HATAMOTO_ORANGE: Color = Color("#f08a2e")

# --- Shared effects ---------------------------------------------------------
const SPIRIT: Color = Color("#8fe3ff")
const MOON: Color = Color("#f3dda4")
const MOON_HALO: Color = Color("#e9b866")

# --- Backdrop: Bamboo Outskirts --------------------------------------------
const SKY_TOP: Color = Color("#1e2238")
const SKY_HORIZON: Color = Color("#77768f")
const MOUNTAIN_FAR: Color = Color("#5d6079")
const MIST: Color = Color("#a3a1b4")
const MOUNTAIN_MID: Color = Color("#666a84")
const BAMBOO_FAR: Color = Color("#757d93")
const BAMBOO_NEAR: Color = Color("#30364a")
const GROUND_TOP: Color = Color("#807e94")
const GROUND_BOTTOM: Color = Color("#1b1a22")

# --- UI ---------------------------------------------------------------------
const UI_CHARCOAL: Color = Color("#1c1a1f")
const UI_BUTTON: Color = Color("#2a272e")
const UI_BUTTON_HOVER: Color = Color("#38333c")
const UI_BUTTON_PRESSED: Color = Color("#141216")
const PARCHMENT: Color = Color("#eadfc4")
const PARCHMENT_DIM: Color = Color("#b8ad94")
const UI_DISABLED: Color = Color("#7a7266")
const GOLD: Color = Color("#c9a24a")
const GOLD_BRIGHT: Color = Color("#e8c46a")
const CRIMSON: Color = Color("#b8322a")
## Readable on charcoal: warnings / defeat text, success / cleared text.
const EMBER_TEXT: Color = Color("#e8795f")
const JADE: Color = Color("#8fcb9b")
## Spirit energy bar fill (deep enough for parchment text on top).
const SPIRIT_DEEP: Color = Color("#2f86b8")

## Backdrop colours that can appear behind a fighter (checked for contrast against INK).
const ACTION_BAND_BACKDROP: Array[Color] = [SKY_HORIZON, MOUNTAIN_FAR, MIST, MOUNTAIN_MID, BAMBOO_FAR, GROUND_TOP]
const ACCENTS: Array[Color] = [SAMURAI_RED, ASHIGARU_GOLD, ARCHER_TEAL, HOLLOW_PURPLE, ONI_EMBER, SPIRIT,
		HEALER_JADE, GUARDIAN_AZURE, ONMYOJI_MAGENTA, HATAMOTO_ORANGE]


## WCAG 2 relative luminance of an sRGB colour.
static func luminance(color: Color) -> float:
	var channels: Array[float] = [color.r, color.g, color.b]
	var linear: Array[float] = []
	for c: float in channels:
		linear.append(c / 12.92 if c <= 0.04045 else pow((c + 0.055) / 1.055, 2.4))
	return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


## WCAG 2 contrast ratio (1..21) between two colours.
static func contrast(a: Color, b: Color) -> float:
	var la: float = luminance(a)
	var lb: float = luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)
