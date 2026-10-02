extends Control

var card_store = {}
var cards
var card_radius = 1500
var _arrange_generation = 0
var _fan_tween = null

func _ready():
	load_card_store()
	#redraw_all_cards()
	arrange_cards()
	pass

func _process(_delta):
	if $Energy:
		$Energy.text = str(game.energy)

func load_card_store():
	card_store = {}
	var cards_json = JSON.parse(helpers.read_file("res://resources/cards.json")).result
	for card in cards_json:
		card_store[card["id"]] = card
	
func draw_rand_card():
	var deck = []
	
	for card in cards:
		deck.push_back(card)
	
	# We want a lot of commit and checkout cards!
	for _i in range(5):
		deck.push_back(cards[0])
		deck.push_back(cards[1])
	
	var card = deck[randi() % deck.size()]
	draw_card(card)

func draw_card(card):
	_spawn_card(card)
	arrange_cards()

func _spawn_card(card):
	var new_card = preload("res://scenes/card.tscn").instance()
	
	new_card.id = card["id"]
	new_card.command = card["command"]
	new_card.description = card["description"]
	new_card.energy = 0 #card.energy
	new_card.position = Vector2(rect_size.x, rect_size.y*2)
	add_child(new_card)
	
func draw(ids):
	_free_existing_cards()
		
	for id in ids:
		_spawn_card(card_store[id])
	
	arrange_cards()
	
	if ids.size() > 0:
		game.notify("这些是你的卡牌！把它们拖到高亮区域即可使用。", self, "cards")

func _free_existing_cards():
	_stop_fan_tween()
	for card in get_tree().get_nodes_in_group("cards"):
		if is_instance_valid(card) and not card.is_queued_for_deletion():
			card.release_for_free()

func _stop_fan_tween():
	if _fan_tween != null and is_instance_valid(_fan_tween) and _fan_tween.is_valid():
		_fan_tween.kill()
	_fan_tween = null

# A Timer/Tween node added here is rejected while this Control is still entering the tree.
# SceneTreeTween is not parented, and a newer deal supersedes an older one.
func arrange_cards():
	if not is_inside_tree():
		return
	_arrange_generation += 1
	var generation = _arrange_generation
	var timer = get_tree().create_timer(0.05)
	timer.connect("timeout", self, "_apply_arrange", [generation])

func _apply_arrange(generation):
	if generation != _arrange_generation or not is_inside_tree():
		return
	var live_cards = []
	for card in get_tree().get_nodes_in_group("cards"):
		if is_instance_valid(card) and not card.is_queued_for_deletion():
			live_cards.append(card)
	_stop_fan_tween()
	if live_cards.empty():
		return

	var amount_cards = live_cards.size()
	var total_angle = min(35, 45.0/7*amount_cards)
	var angle_between_cards = 0
	if amount_cards > 1:
		angle_between_cards = total_angle / (amount_cards-1)
	else:
		total_angle = 0

	var tween = create_tween().bind_node(self).set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_fan_tween = tween
	var current_angle = -total_angle/2
	for card in live_cards:
		var target_position = Vector2(rect_size.x/2, rect_size.y + card_radius)
		var target_rotation = current_angle
		var translation_vec = Vector2(0,-card_radius).rotated(current_angle/180.0*PI)
		target_position += translation_vec
		current_angle += angle_between_cards
		card._home_position = target_position
		card._home_rotation = target_rotation
		tween.tween_property(card, "position", target_position, 0.5)
		tween.tween_property(card, "rotation_degrees", target_rotation, 0.5)
		
func redraw_all_cards():
	game.energy = 5
	_free_existing_cards()

	for card in card_store:
		_spawn_card(card_store[card])
	
	arrange_cards()

func add_card(command):
	draw_card({"command": command, "description": "", "arg_number": 0, "energy": 0})
