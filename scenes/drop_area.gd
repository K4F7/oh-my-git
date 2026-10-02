extends Node2D

var hovered = false
var highlighted = false setget _set_highlighted
var _hover_tween = null

func _ready():
	_set_highlighted(false)
	
func _mouse_entered(_area):
	hovered = true
	_animate_hover(1)

func _mouse_exited(_area):
	hovered = false
	_animate_hover(0)

func _animate_hover(value):
	if not is_inside_tree():
		return
	if _hover_tween != null and is_instance_valid(_hover_tween) and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween().bind_node(self).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_hover_tween.tween_property($Highlight/Sprite.material, "shader_param/hovered", value, 0.1)
	
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and !event.pressed and hovered:
			if highlighted and game.dragged_object:
				game.dragged_object.dropped_on(get_parent_with_type())

func _set_highlighted(new_highlighted):
	highlighted = new_highlighted
	$Highlight.visible = highlighted
	
func get_parent_with_type():
	var parent = get_parent()
	while(!parent.get("type")):
		parent = parent.get_parent()
	return parent

func highlight(type):
	if get_parent_with_type().type == type:
		_set_highlighted(true)
