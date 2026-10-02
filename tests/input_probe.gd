extends SceneTree

# Checks that the editor/terminal shortcuts fire for the platform's command
# key alone (Ctrl on Linux/Windows, Cmd on macOS) and not for the bare key.
# Godot 3 stores "command" in the same field as "control" (or "meta" on
# macOS), so an event saved with only command:true covers both platforms.
# Prints one line per check and exits with 1 if any of them fails.

const SHORTCUTS = {"save": KEY_S, "delete_word": KEY_W, "clear": KEY_L}

func _init():
	var modifier = "meta" if OS.get_name() == "OSX" else "control"
	var failed = false
	for action in SHORTCUTS:
		var with_modifier = _key(SHORTCUTS[action])
		with_modifier.set(modifier, true)
		failed = _check(InputMap.event_is_action(with_modifier, action), "%s+%s fires" % [modifier, action]) or failed
		var bare = _key(SHORTCUTS[action])
		failed = _check(not InputMap.event_is_action(bare, action), "bare %s does not fire" % action) or failed
	quit(1 if failed else 0)

func _key(scancode):
	var event = InputEventKey.new()
	event.scancode = scancode
	event.pressed = true
	return event

func _check(ok, what):
	print("%s %s" % ["ok    " if ok else "FAILED", what])
	return not ok
