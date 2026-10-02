extends Node

# Reports which scene the game ends up in shortly after start-up, so that
# tests/run_tests.sh can check the git availability detection in game.gd
# (it switches to res://scenes/no_git.tscn when git is unusable).
#
#   godot --no-window --path . res://tests/startup_probe.tscn
#
# This node is freed if game.gd changes the scene, so the report runs from a
# Reference kept alive in the SceneTree's metadata.

class Reporter:
	extends Reference

	func report(tree):
		var scene = tree.current_scene
		print("STARTUP_SCENE %s" % (scene.filename if scene else "none"))
		tree.quit(0)

func _ready():
	var reporter = Reporter.new()
	get_tree().set_meta("startup_probe", reporter)
	get_tree().create_timer(1.0).connect("timeout", reporter, "report", [get_tree()])
