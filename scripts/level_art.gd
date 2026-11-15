extends Node2D
# Dessine la roche, la mousse pâle et les pics à partir de la carte.

var main


func _cell(x: int, y: int) -> bool:
	return main.solid.has(Vector2i(x, y))

func _hash(x: int, y: int) -> float:
	return fposmod(sin(x * 12.9898 + y * 78.233) * 43758.5453, 1.0)

func _draw() -> void:
	var T: int = main.TILE
	var rock: Color = main.pal["rock"]
	var rock_hi: Color = main.pal["rock_hi"]
	var moss: Color = main.pal["moss"]
	var spike_col: Color = main.pal["spike"]
	for c in main.solid.keys():
		var x: int = c.x
		var y: int = c.y
		var r := Rect2(x * T, y * T, T, T)
		draw_rect(r, rock)
		var h := _hash(x, y)
		if h > 0.7:
			draw_circle(r.position + Vector2(8 + h * 14, 10 + h * 10), 2.0 + h * 2.0, rock_hi)
		var up := not _cell(x, y - 1)
		var down := not _cell(x, y + 1)
		var left := not _cell(x - 1, y)
		var right := not _cell(x + 1, y)
		if left:
			draw_rect(Rect2(r.position, Vector2(3, T)), rock_hi)
		if right:
			draw_rect(Rect2(r.position + Vector2(T - 3, 0), Vector2(3, T)), rock_hi)
		if down:
			draw_rect(Rect2(r.position + Vector2(0, T - 3), Vector2(T, 3)), rock_hi)
			if h > 0.55:   # petites stalactites
				var sx := r.position.x + 6 + h * 18
				draw_colored_polygon(PackedVector2Array([Vector2(sx - 4, r.end.y), Vector2(sx + 4, r.end.y), Vector2(sx, r.end.y + 8 + h * 10)]), rock_hi)
		if up:
			draw_rect(Rect2(r.position, Vector2(T, 4)), moss)
			for i in 3:
				var hx := r.position.x + 4 + i * 10 + _hash(x + i, y) * 6
				var hh := 3.0 + _hash(x, y + i) * 6.0
				draw_line(Vector2(hx, r.position.y), Vector2(hx + 1, r.position.y - hh), moss, 1.5)
	for s in main.spikes:
		var n := 3
		var w: float = s.size.x / n
		for i in n:
			var bx: float = s.position.x + i * w
			draw_colored_polygon(PackedVector2Array([Vector2(bx, s.end.y), Vector2(bx + w, s.end.y), Vector2(bx + w / 2.0, s.position.y)]), spike_col)
