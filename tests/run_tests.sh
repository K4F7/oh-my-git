#!/usr/bin/env bash
# Runs the level harness: every level once, then every exploratory case in its
# own process so that a case which makes the game quit is reported by name.
#
#   GODOT=/path/to/godot tests/run_tests.sh
#
# GODOT defaults to "godot". With a windowed (X11) build, a display is needed;
# use xvfb-run on headless machines.
set -u
cd "$(dirname "$0")/.."
godot="${GODOT:-godot}"
log_dir="${LOG_DIR:-$(mktemp -d)}"
mkdir -p "$log_dir"
failed=0

run_harness() {
	local log="$1"; shift
	"$godot" --no-window --path . res://tests/level_harness.tscn "$@" > "$log" 2>&1
	local code=$?
	if ! grep -q '^TOTAL ' "$log"; then
		echo "CRASHED $* (game quit before the summary, see $log)"
		grep -m1 'FATAL ERROR' "$log"
		return 1
	fi
	grep -E '^  FAIL ' "$log"
	return $code
}

run_harness "$log_dir/levels.log" || failed=1
grep '^TOTAL ' "$log_dir/levels.log"

for case in $(grep -oE '^	"[a-z0-9-]+": \{"level"' tests/solutions.gd | cut -d'"' -f2); do
	if run_harness "$log_dir/explore-$case.log" --explore --only="$case" > /dev/null; then
		echo "ok      explore/$case"
	else
		echo "FAILED  explore/$case (see $log_dir/explore-$case.log)"
		failed=1
	fi
done

echo "logs: $log_dir"
exit $failed
