extends Node

# Plays levels through the real main scene: loads a level, types commands into
# the in-game terminal (answering the in-game editor when a command opens it)
# and evaluates the level's own win conditions with Level.check_win().
#
#   godot --no-window --path . res://tests/level_harness.tscn [--only=<name>]
#   godot --no-window --path . res://tests/level_harness.tscn --explore [--only=<name>]
#   godot --no-window --path . res://tests/level_harness.tscn --list-explore
#
# The default mode plays every level with its entry in Solutions.SOLUTIONS.
# --explore runs Solutions.EXPLORATORY instead. The process exits with the
# number of failures; a missing "TOTAL" line means the game quit itself
# (helpers.crash()) in the middle of the run. tests/run_tests.sh wraps this.

const Solutions = preload("res://tests/solutions.gd")
const COMMAND_TIMEOUT_MSEC = 20000
const SETTLE_FRAMES = 30

var main
var terminal
var results = []

func _ready():
	call_deferred("_run")

func _run():
	# Never touch the player's real save game.
	game._file = "user://test_savegame.json"
	game.state = game._initial_state()

	main = preload("res://scenes/main.tscn").instance()
	main.name = "Main"
	get_tree().root.add_child(main)
	terminal = main.terminal
	yield(get_tree(), "idle_frame")

	var args = helpers.parse_args()
	if args.has("list-explore"):
		for name in Solutions.EXPLORATORY:
			print("EXPLORE %s" % name)
		get_tree().quit(0)
		return
	var only = args.get("only", "")
	var cases = Solutions.EXPLORATORY if args.has("explore") else _level_cases()
	for name in cases:
		if only != "" and only != name:
			continue
		var state = _play(name, cases[name])
		while state is GDScriptFunctionState:
			state = yield(state, "completed")
	if results.empty():
		results.push_back([only, "FAIL", "no case selected"])
	_report()

func _level_cases():
	var cases = {}
	for chapter in levels.chapters:
		for level in chapter.levels:
			var slug = chapter.slug + "/" + level.slug
			cases[slug] = {"level": slug, "steps": Solutions.SOLUTIONS.get(slug, null), "goals": true}
	return cases

func _play(name, spec):
	print("=== CASE %s" % name)
	var level = _load_level(spec["level"])
	var failure = ""
	if level == null:
		failure = "unknown level %s" % spec["level"]
	elif spec["steps"] == null:
		failure = "no solution"
	else:
		for step in spec["steps"]:
			var state = _run_step(step)
			while state is GDScriptFunctionState:
				state = yield(state, "completed")
			if state != "":
				failure = state
				break
		# Let deferred file browser updates and node drawing run.
		for _i in range(SETTLE_FRAMES):
			yield(get_tree(), "idle_frame")

	var output = terminal.output.text
	if failure == "" and spec.has("expect") and output.find(spec["expect"]) == -1:
		failure = "terminal output lacks '%s'" % spec["expect"]
	if failure == "" and spec.has("reject") and output.find(spec["reject"]) != -1:
		failure = "terminal output contains '%s'" % spec["reject"]

	if failure == "" and spec.has("notification") and not spec["notification"] in _notification_texts():
		failure = "no notification '%s' (got %s)" % [spec["notification"], _notification_texts()]

	# Exploratory cases only check that the game survives, not the level goals.
	var goals_met = true
	var win_states = {}
	if level != null and spec.get("goals", false):
		win_states = level.check_win()
	for goal in win_states:
		print("  goal [%s] %s" % ["x" if win_states[goal] else " ", goal])
		goals_met = goals_met and win_states[goal]
	if failure == "" and not goals_met:
		failure = "win conditions not met"

	var status = "PASS"
	if failure != "":
		status = "FAIL"
	elif win_states.empty() and spec.get("goals", false):
		if spec["level"] in Solutions.NO_GOAL_LEVELS:
			status = "NOGOALS"
		else:
			status = "FAIL"
			failure = "level has no goals"
	print("  %s %s %s" % [status, name, failure])
	results.push_back([name, status, failure])

func _notification_texts():
	var texts = []
	for node in get_tree().root.get_children():
		if node.get_script() == preload("res://scenes/notification.gd"):
			texts.push_back(node.text)
	return texts

func _load_level(slug):
	for chapter_id in range(levels.chapters.size()):
		var chapter = levels.chapters[chapter_id]
		for level_id in range(chapter.levels.size()):
			if chapter.slug + "/" + chapter.levels[level_id].slug == slug:
				game.current_chapter = chapter_id
				main.load_level(level_id)
				return chapter.levels[level_id]
	return null

func _run_step(step):
	var command = step["cmd"] if step is Dictionary else step
	var wants_editor = step is Dictionary
	print("  $ %s" % command)
	# Saving the in-game editor emits command_done too (Terminal.editor_saved),
	# so an editor step is only finished after the second emission.
	var expected_signals = 2 if wants_editor else 1
	var done = [0]
	terminal.connect("command_done", self, "_on_command_done", [done])
	terminal.send_command(command)
	var editor = terminal.find_node("TextEditor")
	var answered_editor = false
	var started = OS.get_ticks_msec()
	var failure = ""
	while done[0] < expected_signals:
		if OS.get_ticks_msec() - started > COMMAND_TIMEOUT_MSEC:
			failure = "timeout running '%s'" % command
			break
		if wants_editor and not answered_editor and editor.visible:
			answered_editor = true
			if step.has("shows") and editor.text.find(step["shows"]) == -1:
				failure = "editor shows '%s', expected '%s'" % [editor.text, step["shows"]]
			_answer_editor(editor, step)
		yield(get_tree(), "idle_frame")
	terminal.disconnect("command_done", self, "_on_command_done")
	if failure == "" and wants_editor and not answered_editor:
		failure = "editor never opened for '%s'" % command
	_print_output_tail()
	return failure

func _on_command_done(done):
	done[0] += 1

func _answer_editor(editor, step):
	if step.has("reorder"):
		editor.text = _reorder_lines(editor.text, step["reorder"])
	elif step.get("editor") != null:
		editor.text = step["editor"]
	editor.save()

# Permutes the non-comment lines of an editor buffer, e.g. the todo list of an
# interactive rebase.
func _reorder_lines(text, order):
	var picks = []
	var rest = []
	for line in text.split("\n"):
		if line.begins_with("#") or line.strip_edges() == "":
			rest.push_back(line)
		else:
			picks.push_back(line)
	var reordered = []
	for i in order:
		reordered.push_back(picks[i])
	return PoolStringArray(reordered + rest).join("\n")

func _print_output_tail():
	var lines = terminal.output.text.split("\n")
	for i in range(max(0, lines.size() - 12), lines.size()):
		if lines[i] != "":
			print("    | %s" % lines[i])

func _report():
	var counts = {"PASS": 0, "FAIL": 0, "NOGOALS": 0}
	print("=== SUMMARY")
	for r in results:
		print("%-45s %s %s" % r)
		counts[r[1]] += 1
	print("TOTAL %d PASS %d FAIL %d NOGOALS %d" % [results.size(), counts["PASS"], counts["FAIL"], counts["NOGOALS"]])
	get_tree().quit(counts["FAIL"])
