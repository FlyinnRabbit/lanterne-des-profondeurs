shader_type canvas_item;
render_mode unshaded;
// Contour des ennemis élites. L'ennemi est rendu comme un groupe (canvas group) : on lit sa
// silhouette dans l'image du groupe et on trace autour un liseré rouge net, plus une lueur
// qui pulse. Même rouge dans tous les biomes (pas d'éclairage).
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform vec4 line_color : source_color = vec4(1.0, 0.18, 0.12, 1.0);
uniform float line_px = 1.6;
uniform float glow_px = 5.0;

float around(vec2 uv, vec2 px) {
	float a = 0.0;
	for (int i = 0; i < 12; i++) {
		float ang = float(i) * 6.2831853 / 12.0;
		a = max(a, textureLod(screen_texture, uv + vec2(cos(ang), sin(ang)) * px, 0.0).a);
	}
	return a;
}

void fragment() {
	vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);
	if (c.a > 0.0001) {
		c.rgb /= c.a;
	}
	float pulse = 0.5 + 0.5 * sin(TIME * 3.2);
	float line = around(SCREEN_UV, SCREEN_PIXEL_SIZE * line_px);
	float glow = 0.0;
	for (int r = 1; r <= 3; r++) {
		glow = max(glow, around(SCREEN_UV, SCREEN_PIXEL_SIZE * (line_px + glow_px * float(r) / 3.0)) * (1.0 - float(r - 1) / 3.0));
	}
	vec4 edge = vec4(line_color.rgb, max(line * (0.75 + 0.25 * pulse), glow * (0.25 + 0.35 * pulse)));
	// le corps de l'ennemi par-dessus, son contour et sa lueur dessous
	COLOR = vec4(mix(edge.rgb, c.rgb, c.a), c.a + edge.a * (1.0 - c.a));
}
