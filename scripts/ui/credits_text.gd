class_name CreditsText
extends RefCounted
## Turns docs/CREDITS.md into the text the Credits screen shows (BBCode for a RichTextLabel), so the screen
## shows exactly what the credits file says: the creator line and the credits a licence REQUIRES, nothing else (every
## other asset is recorded in docs/ASSET_LICENSES.md, which the game never loads). Handles what that file uses: "#"
## and "##" headings, "- " bullets, **bold**, `code` and https links.

const FILE_PATH: String = "res://docs/CREDITS.md"
## Shown if the file cannot be read (a build that does not ship docs/). The credits a licence REQUIRES are
## never left out.
const FALLBACK: String = """# Credits

Created by Muhammad Nazhan Syahmi

Music: Free Music : MOMIZizm MUSiC - https://music.storyinvention.com/en/
"""


## The credits file's text, or FALLBACK.
static func load_markdown(path: String = FILE_PATH) -> String:
	if FileAccess.file_exists(path):
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file != null:
			var text: String = file.get_as_text()
			if not text.strip_edges().is_empty():
				return text
	return FALLBACK


static func to_bbcode(markdown: String) -> String:
	var bold: RegEx = RegEx.create_from_string("\\*\\*(.+?)\\*\\*")
	var code: RegEx = RegEx.create_from_string("`([^`]+)`")
	var link: RegEx = RegEx.create_from_string("(https?://[^\\s\\)\\],;]+[^\\s\\)\\],;.])")
	var lines: PackedStringArray = PackedStringArray()
	# A paragraph of the file is hard-wrapped over several lines: join them, as markdown does.
	var paragraph: PackedStringArray = PackedStringArray()
	var raw_lines: PackedStringArray = markdown.replace("\r", "").split("\n")
	raw_lines.append("")
	for raw: String in raw_lines:
		# "[" starts a BBCode tag: write it as an escaped bracket before adding our own tags.
		var line: String = raw.replace("[", "[lb]")
		var continues: bool = not line.strip_edges().is_empty() and not line.begins_with("#") and not line.begins_with("- ")
		if continues:
			paragraph.append(line.strip_edges())
			continue
		if not paragraph.is_empty():
			lines.append(_inline(" ".join(paragraph), bold, code, link))
			paragraph.clear()
		if line.begins_with("## "):
			lines.append("\n[font_size=40][color=#e8c46a][b]%s[/b][/color][/font_size]" % line.substr(3))
		elif line.begins_with("# "):
			lines.append("[font_size=56][b]%s[/b][/font_size]" % line.substr(2))
		elif line.begins_with("- "):
			lines.append("   •  %s" % _inline(line.substr(2), bold, code, link))
		else:
			lines.append("")
	return "\n".join(lines)


static func _inline(text: String, bold: RegEx, code: RegEx, link: RegEx) -> String:
	text = bold.sub(text, "[b]$1[/b]", true)
	text = code.sub(text, "[color=#b8ad94]$1[/color]", true)
	return link.sub(text, "[url]$1[/url]", true)


## Only web links are opened from the credits.
static func is_openable(meta: Variant) -> bool:
	var target: String = str(meta)
	return target.begins_with("https://") or target.begins_with("http://")
