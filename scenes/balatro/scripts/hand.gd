extends Control

signal deal_finished
signal play_requested(card: Control)

var allow_play := false
var conceal_hand := false

func rebuild(count: int) -> void:
	for card in cards:
		_stop_slide(card)
	for child in get_children():
		remove_child(child)
		child.queue_free()
	cards.clear()
	card_variations.clear()
	dragged_card = null
	for _i in range(count):
		var card = load("res://scenes/balatro/card.tscn").instantiate()
		add_child(card)
		_register_card(card)
	_arrange(false)

func _register_card(card: Control) -> void:
	cards.append(card)
	card_variations[card] = Vector2(randf_range(-vertical_variation, vertical_variation), randf_range(-rotation_variation, rotation_variation))
	card.drag_started.connect(_on_drag_started)
	card.drag_moved.connect(_on_drag_moved)
	card.drag_ended.connect(_on_drag_ended)

func commit_card(card: Control, keep_position: bool = false) -> void:
	_stop_slide(card)
	cards.erase(card)
	card_variations.erase(card)
	dragged_card = null
	card.drag_started.disconnect(_on_drag_started)
	card.drag_moved.disconnect(_on_drag_moved)
	card.drag_ended.disconnect(_on_drag_ended)
	table.show_target(false)
	table.play_card(card, true, keep_position)
	_arrange()

func return_card(card: Control) -> void:
	if not is_instance_valid(card):
		return
	table.cards.erase(card)
	card.reparent(self, true)
	card.is_played = false
	card.play_preview = false
	card.disabled = false
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	_register_card(card)
	_arrange()

@export var card_spacing: float = -24.0
@export var vertical_variation: float = 6.0
@export var rotation_variation: float = 1.5
@export var fan_angle: float = 3.0
@export var fan_curve: float = 12.0
@export var slide_duration: float = 0.18
@export var play_area: NodePath = NodePath("../../PlayArea")

@onready var table = get_node_or_null(play_area)

var cards: Array[Control] = []
var dragged_card: Control
var slides: Dictionary = {}
var is_dealing: bool = false
var card_variations: Dictionary = {}

func deal_from(deck, pile, participants: int = 1, full_deck: bool = false) -> void:
	if is_dealing:
		return
	is_dealing = true
	pile.card_count = 40 if full_deck else deck.remaining_count()
	for card in cards:
		_stop_slide(card)
		card.is_dealing = true
		card.disabled = true
		card.hide()
	await get_tree().create_timer(1.0, false).timeout
	await pile.prepare_deal()
	for index in range(cards.size()):
		var origin: Vector2 = pile.top_global_position()
		var drawn = deck.draw(1)
		if drawn.is_empty():
			break
		pile.card_count = 40 - (index + 1) * participants if full_deck else deck.remaining_count()
		var card = cards[index]
		card.set_card_data(drawn[0])
		card.set_face_down(true)
		card.global_position = origin
		card.rotation = -0.06
		card.z_index = 100
		card.show()
		preload("res://scenes/balatro/scripts/game_audio.gd").play(self, preload("res://scenes/balatro/scripts/game_audio.gd").SWIPE, -18.0)
		var flight := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		flight.tween_property(card, "position", _slot_position(index), 0.16)
		flight.tween_property(card, "rotation", _slot_rotation(index), 0.16)
		await flight.finished
		var flip := create_tween()
		flip.tween_property(card, "scale:x", 0.0, 0.035)
		flip.tween_callback(card.set_face_down.bind(conceal_hand))
		flip.tween_property(card, "scale:x", 1.0, 0.045)
		await flip.finished
		card.z_index = 0
	await pile.return_home()
	is_dealing = false
	for card in cards:
		card.is_dealing = false
		card.disabled = false
	_arrange(false)
	deal_finished.emit()

func _ready() -> void:
	# Grow around the bottom centre, keeping the hand centred and above the edge.
	pivot_offset = Vector2(size.x / 2.8, size.y / 1.5)
	for child in get_children():
		if child is Control and child.has_signal("drag_started"):
			_register_card(child)
	resized.connect(_on_resized)
	_arrange(false)

func _slot_position(index: int) -> Vector2:
	var card_size := cards[index].size
	var total_width := card_size.x * cards.size() + card_spacing * (cards.size() - 1)
	return Vector2((size.x - total_width) / 2.0 + index * (card_size.x + card_spacing), 0.0)

func _slot_rotation(_index: int) -> float:
	return 0.0

func _arrange(animated: bool = true) -> void:
	if is_dealing:
		return
	for index in range(cards.size()):
		var card := cards[index]
		# Match input order to the visible order, even after repeated drags.
		move_child(card, index)
		if card == dragged_card:
			continue
		_stop_slide(card)
		if animated:
			var slide := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			slide.tween_property(card, "position", _slot_position(index), slide_duration)
			slide.parallel().tween_property(card, "rotation", _slot_rotation(index), slide_duration)
			slides[card] = slide
		else:
			card.position = _slot_position(index)
			card.rotation = _slot_rotation(index)

func _stop_slide(card: Control) -> void:
	if slides.has(card):
		var slide: Tween = slides[card]
		if slide.is_valid():
			slide.kill()
		slides.erase(card)

func _on_drag_started(card: Control) -> void:
	dragged_card = card
	_stop_slide(card)
	if table:
		table.show_target(allow_play)

func _on_drag_moved(card: Control) -> void:
	if card != dragged_card:
		return
	if table:
		var aiming: bool = allow_play and table.contains_card(card)
		card.set_play_preview(aiming)
		table.show_target(allow_play, aiming)
		if aiming:
			return
	# Use fixed slots: animated neighbours must not move the insertion thresholds.
	var center_x := card.position.x + card.size.x / 2.0
	var target_index := 0
	var nearest_distance := INF
	for index in range(cards.size()):
		var distance := absf(center_x - (_slot_position(index).x + card.size.x / 2.0))
		if distance < nearest_distance:
			nearest_distance = distance
			target_index = index
	if target_index != cards.find(card):
		cards.erase(card)
		cards.insert(target_index, card)
		_arrange()

func _on_drag_ended(card: Control) -> void:
	if card != dragged_card:
		return
	if table and allow_play and not card.drag_cancelled and table.contains_card(card):
		play_requested.emit(card)
	_on_drag_moved(card)
	card.set_play_preview(false)
	if table:
		table.show_target(false)
	dragged_card = null
	_arrange()

func _on_resized() -> void:
	pivot_offset = Vector2(size.x / 2.0, size.y)
	_arrange()
