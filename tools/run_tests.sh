#!/usr/bin/env bash
# Lance tous les tests tests/test_*.gd (sous xvfb, rendu opengl3) et affiche un bilan.
# Un test échoue s'il affiche « SCRIPT ERROR », « ÉCHEC » / « FAIL », ou dépasse le délai.
# Usage : tools/run_tests.sh [godot] [filtre] — ex. tools/run_tests.sh ./godot elder
# Variables : TEST_TIMEOUT (s, défaut 300), TEST_JOBS (tests en parallèle, défaut 2).
set -u
GODOT="${1:-godot}"
FILTER="${2:-}"
TIMEOUT="${TEST_TIMEOUT:-300}"
JOBS="${TEST_JOBS:-2}"
cd "$(dirname "$0")/.."

# Tests qui ne vérifient rien (captures d'écran pour l'œil humain).
SKIP="test_hubshots test_ctrlshot"

# Serveurs de classement locaux pour test_leaderboard (8787) et test_http_v4 (8797).
SERVERS=()
if command -v node >/dev/null; then
	node server/dev_server.mjs 8787 >/dev/null 2>&1 & SERVERS+=($!)
	node server/dev_server.mjs 8797 >/dev/null 2>&1 & SERVERS+=($!)
	export LANTERNE_LEADERBOARD_URL="http://127.0.0.1:8787"
	sleep 1
	for pid in "${SERVERS[@]}"; do
		kill -0 "$pid" 2>/dev/null || echo "⚠ serveur de classement local arrêté (Node 22.13+ requis pour node:sqlite)"
	done
fi
trap 'kill ${SERVERS[@]:-} 2>/dev/null' EXIT

OUT="$(mktemp -d)"
run_one() {
	local t="$1" name log start code dur verdict
	name="$(basename "$t" .gd)"
	log="$OUT/$name.log"
	start=$(date +%s)
	# chaque test a ses propres sauvegardes (dossier utilisateur vierge) : pas d'interférence
	# entre tests lancés en parallèle ni de dépendance aux parties précédentes
	export XDG_DATA_HOME="$OUT/data_$name"
	mkdir -p "$XDG_DATA_HOME"
	setsid timeout "$TIMEOUT" xvfb-run -a -s "-screen 0 1280x720x24" "$GODOT" --path . \
		--rendering-driver opengl3 --resolution 1280x720 --audio-driver Dummy -s "$t" >"$log" 2>&1 &
	local pid=$!
	# une erreur de script fige le test sans le quitter : on l'arrête tout de suite
	while kill -0 $pid 2>/dev/null; do
		if grep -q "SCRIPT ERROR" "$log" 2>/dev/null; then
			sleep 2
			kill -- -$pid 2>/dev/null
			break
		fi
		sleep 2
	done
	wait $pid 2>/dev/null
	code=$?
	dur=$(( $(date +%s) - start ))
	if [ $code -eq 124 ]; then verdict="DÉLAI"
	elif grep -q "SCRIPT ERROR" "$log"; then verdict="ERREUR"
	elif grep -qE "ÉCHEC|FAIL" "$log"; then verdict="ÉCHEC"
	else verdict="OK"; fi
	printf "%-6s %4ss  %s\n" "$verdict" "$dur" "$name" | tee -a "$OUT/_bilan"
}
export -f run_one
export OUT GODOT TIMEOUT
# les tests lisent les textes du jeu en français (la langue suit celle du système)
export LANG=fr_FR.UTF-8; unset LC_ALL

TESTS=()
for t in tests/test_*.gd; do
	n="$(basename "$t" .gd)"
	[[ " $SKIP " == *" $n "* ]] && continue
	[ -n "$FILTER" ] && [[ "$n" != *"$FILTER"* ]] && continue
	TESTS+=("$t")
done
printf "%s\n" "${TESTS[@]}" | xargs -P "$JOBS" -I{} bash -c 'run_one "$@"' _ {}

echo
FAILS=$(grep -vc "^OK" "$OUT/_bilan" || true)
TOTAL=$(wc -l <"$OUT/_bilan")
for f in $(grep -v "^OK" "$OUT/_bilan" | awk '{print $3}'); do
	echo "──── $f ────"
	grep -vE "^\s*$|keyboard_get_keycode|Not supported by this display|V-Sync|set_use_vsync|^OpenGL|^Godot Engine|leaked at exit|still in use at exit|at: (cleanup|clear) " "$OUT/$f.log" | tail -25
done
echo "Bilan : $((TOTAL - FAILS)) / $TOTAL tests OK"
[ "$FAILS" -eq 0 ]
