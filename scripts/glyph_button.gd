extends Button
# Case du menu Commandes : affiche l'icône de la touche / du bouton (et son nom pour la manette).

const G = preload("res://scripts/glyphs.gd")

var glyph: Dictionary = {}
var caption := ""

func _draw() -> void:
	if glyph.is_empty():
		return
	var font := get_theme_font("font")
	var h := size.y * 0.72
	var w := G.width(glyph, h, font)
	var fs := 14
	var cap_w := 0.0
	if caption != "":
		cap_w = font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 8.0
	var x := (size.x - w - cap_w) / 2.0
	G.draw(self, x, size.y / 2.0, h, glyph, font)
	if caption != "":
		draw_string(font, Vector2(x + w + 8.0, size.y / 2.0 + fs * 0.36), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.85, 0.88, 0.95))
