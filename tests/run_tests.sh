#!/usr/bin/env bash
# Runs the level harness: every level once, then every exploratory case in its
# own process so that a case which makes the game quit is reported by name.
#
#   GODOT=/path/to/godot tests/run_tests.sh
#
# GODOT defaults to "godot". The headless Linux build needs no display; a
# windowed (X11) build needs DISPLAY (or xvfb-run).
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

cases=$("$godot" --no-window --path . res://tests/level_harness.tscn --list-explore 2>/dev/null | sed -n 's/^EXPLORE //p')
if [ -z "$cases" ]; then
	echo "FAILED  could not list exploratory cases"
	failed=1
fi
for case in $cases; do
	if run_harness "$log_dir/explore-$case.log" --explore --only="$case" > /dev/null; then
		echo "ok      explore/$case"
	else
		echo "FAILED  explore/$case (see $log_dir/explore-$case.log)"
		failed=1
	fi
done

# A git that is found on PATH but cannot run (like macOS' /usr/bin/git stub
# without the Command Line Tools) must lead to the no_git screen, not a quit.
broken_git_dir="$log_dir/broken-git"
mkdir -p "$broken_git_dir"
printf '#!/bin/sh\necho "xcrun: error: invalid active developer path" >&2\nexit 1\n' > "$broken_git_dir/git"
chmod +x "$broken_git_dir/git"
PATH="$broken_git_dir:$PATH" "$godot" --no-window --path . res://tests/startup_probe.tscn > "$log_dir/broken-git.log" 2>&1
if grep -q '^STARTUP_SCENE res://scenes/no_git.tscn$' "$log_dir/broken-git.log"; then
	echo "ok      startup/broken-git"
else
	echo "FAILED  startup/broken-git (see $log_dir/broken-git.log)"
	failed=1
fi

# Ctrl+S / Cmd+S etc. must each trigger the shortcut on their own.
if "$godot" --no-window --path . -s res://tests/input_probe.gd > "$log_dir/shortcuts.log" 2>&1; then
	echo "ok      input/shortcuts"
else
	echo "FAILED  input/shortcuts (see $log_dir/shortcuts.log)"
	grep '^FAILED' "$log_dir/shortcuts.log"
	failed=1
fi

echo "logs: $log_dir"
exit $failed
