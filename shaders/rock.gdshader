shader_type canvas_item;
// Matière de la roche, peinte en coordonnées du monde (aucune image).
// style : 0 roche, 1 maçonnerie, 2 cristal, 3 roche volcanique, 4 glace, 5 alvéoles, 6 ossements, 7 humus
uniform int style = 0;
uniform vec4 accent : source_color = vec4(1.0);
varying vec2 wp;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
vec2 h22(vec2 p) { return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), u.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 4; i++) { v += a * noise(p); p = p * 2.03 + 17.1; a *= 0.5; }
	return v;
}
// distance au bord de cellule de Voronoï (x) et identifiant de cellule (y)
vec2 voro(vec2 p) {
	vec2 n = floor(p); vec2 f = fract(p);
	float d1 = 8.0; float d2 = 8.0; float id = 0.0;
	for (int j = -1; j <= 1; j++) for (int i = -1; i <= 1; i++) {
		vec2 g = vec2(float(i), float(j));
		vec2 o = h22(n + g);
		float d = length(g + o - f);
		if (d < d1) { d2 = d1; d1 = d; id = h21(n + g); } else if (d < d2) { d2 = d; }
	}
	return vec2(d2 - d1, id);
}

void fragment() {
	vec2 p = wp;
	float big = fbm(p / 140.0);
	float mid = fbm(p / 38.0 + 11.0);
	float fine = noise(p / 5.0);
	float shade = 0.72 + 0.5 * big + 0.22 * (mid - 0.5) + 0.06 * (fine - 0.5);
	vec3 add = vec3(0.0);
	if (style == 1) {
		// pierres taillées en assises décalées
		vec2 b = p / vec2(56.0, 28.0);
		float row = floor(b.y);
		b.x += mod(row, 2.0) * 0.5;
		vec2 id = floor(b); vec2 f = fract(b);
		float mortar = min(min(f.x, 1.0 - f.x) * 56.0, min(f.y, 1.0 - f.y) * 28.0);
		shade *= 0.82 + 0.3 * h21(id);
		shade *= mix(0.45, 1.0, smoothstep(0.5, 3.0, mortar));
		shade *= 1.0 + 0.18 * smoothstep(3.0, 0.5, f.y * 28.0) * step(0.0, f.y); // arête haute éclairée
		shade *= 1.0 - 0.15 * smoothstep(0.6, 0.9, mid);
	} else if (style == 2) {
		vec2 v = voro(p / 46.0);
		shade *= 0.7 + 0.5 * v.y;
		shade *= mix(0.5, 1.0, smoothstep(0.0, 0.08, v.x));
		add += accent.rgb * 0.35 * smoothstep(0.03, 0.0, v.x) * step(0.55, v.y);
		add += accent.rgb * 0.5 * step(0.985, h21(floor(p / 3.0)));
	} else if (style == 3) {
		vec2 v = voro(p / 64.0 + vec2(big * 1.5));
		shade *= mix(0.55, 1.0, smoothstep(0.0, 0.1, v.x));
		float vein = smoothstep(0.045, 0.0, v.x) * smoothstep(0.35, 0.75, big);
		add += accent.rgb * vein * 0.9;
	} else if (style == 4) {
		shade = 0.72 + 0.3 * big + 0.12 * (noise(vec2(p.x / 60.0 + p.y / 30.0, p.y / 200.0)) - 0.5);
		float crack = voro(p / 70.0).x;
		shade *= mix(0.7, 1.0, smoothstep(0.0, 0.05, crack));
		add += accent.rgb * 0.18 * smoothstep(0.7, 1.0, noise(vec2((p.x + p.y) / 9.0, p.y / 90.0)));
	} else if (style == 5) {
		vec2 q = p / 22.0;
		vec2 r = vec2(1.0, 1.732);
		vec2 a = mod(q, r) - r * 0.5;
		vec2 b = mod(q - r * 0.5, r) - r * 0.5;
		vec2 g = dot(a, a) < dot(b, b) ? a : b;
		float e = 0.5 - max(abs(g.x) * 0.866 + abs(g.y) * 0.5, abs(g.y));
		shade *= mix(0.5, 1.0, smoothstep(0.0, 0.08, e));
		shade *= 0.85 + 0.25 * smoothstep(0.1, 0.4, e);
		add += accent.rgb * 0.18 * smoothstep(0.15, 0.45, e) * step(0.6, mid);
	} else if (style == 6) {
		float bone = smoothstep(0.66, 0.72, fbm(p / 26.0 + 3.0));
		add += accent.rgb * bone * 0.28;
		shade *= mix(0.6, 1.0, smoothstep(0.0, 0.06, voro(p / 52.0).x));
	} else {
		// roche naturelle : strates et fissures
		float strata = sin(p.y / 13.0 + big * 7.0 + mid * 2.0) * 0.5 + 0.5;
		shade *= 0.9 + 0.16 * smoothstep(0.75, 1.0, strata);
		shade *= mix(0.72, 1.0, smoothstep(0.0, 0.03, voro(p / 58.0 + vec2(big * 2.0, mid)).x + (mid - 0.5) * 0.04));
		shade *= mix(0.85, 1.0, smoothstep(0.0, 0.02, voro(p / 21.0 + 4.0).x));
		if (style == 7) {
			add += accent.rgb * 0.12 * smoothstep(0.6, 0.8, fbm(p / 30.0 + 5.0));
		}
		add += accent.rgb * 0.12 * step(0.992, h21(floor(p / 4.0)));
	}
	COLOR.rgb = COLOR.rgb * shade + add * COLOR.rgb * 2.5 + add * 0.15;
}
