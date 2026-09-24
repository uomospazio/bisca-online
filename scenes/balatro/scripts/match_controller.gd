extends Control

const Rules = preload("res://scenes/balatro/scripts/match_rules.gd")
const GameAudio = preload("res://scenes/balatro/scripts/game_audio.gd")
var bot_policy = preload("res://scenes/balatro/scripts/local_bot_policy.gd").new()
var local_bot_generation := 0
const LOCAL_BOT_PREDICTION_DELAY := 0.3
const LOCAL_BOT_PLAY_DELAY := 0.3
const Deck = preload("res://scenes/balatro/scripts/deck.gd")
const CardScene = preload("res://scenes/balatro/card.tscn")
var BACK: Texture2D:
	get:
		var settings = get_node_or_null("/root/GameSettings")
		return settings.back_texture() if settings else preload("res://scenes/balatro/trick_asset/mazzo_2/briscola/back/back1.png")
const PlayerBadge = preload("res://scenes/balatro/scripts/player_badge.gd")
const MainMenu = preload("res://scenes/balatro/scripts/main_menu.gd")
const GameOverlay = preload("res://scenes/balatro/scripts/game_overlay.gd")
const UIHover = preload("res://scenes/balatro/scripts/ui_hover.gd")
const HoldButton = preload("res://scenes/button_fill_animate/hold_button.gd")
const KIDS_FONT = preload("res://scenes/balatro/fonts/Comic Lemon.otf")
const MixedLabel = preload("res://scenes/balatro/scripts/mixed_label.gd")
const ButtonShadow = preload("res://scenes/balatro/scripts/button_shadow.gd")
const RoundedSquareButton = preload("res://scenes/balatro/scripts/rounded_square_button.gd")
const LexispellStyle = preload("res://scenes/balatro/scripts/lexispell_style.gd")
const BUTTON_PURPLE := LexispellStyle.NORMAL
const BUTTON_PURPLE_PRESSED := LexispellStyle.NORMAL
const BUTTON_CYAN := LexispellStyle.HOVER
const BUTTON_DISABLED := LexispellStyle.DISABLED
const BUTTON_TEXT := LexispellStyle.TEXT
const JOKER_BUTTON_RADIUS := 16

@export_range(2, 8) var player_count := 3
var rules = Rules.new()
var catalog := {}
var busy := true
var pending_joker: Control
var status: MixedLabel
var scores: Control
var actions: HBoxContainer
var joker_cancel_area: Control
var joker_buttons: Array = []
var results: MixedLabel
var result_panel: PanelContainer
var table_visuals: Dictionary = {}
var displayed_taken: Dictionary = {}
var local_name := "Giocatore"
var game_ui: Control
var menu: Control
var overlay: Control
var loading_screen: CanvasLayer
var pause_menu: CanvasLayer
var damage_shade: ColorRect
var last_turn_notice := ""
const TURN_SECONDS := 30.0
var turn_time_left := 0.0
var timed_turn := ""
var turn_clock: Label
var online := false
var online_match = preload("res://scenes/balatro/scripts/online_match.gd").new()
var prediction_focus := false
var presented_damage_round := -1
var prediction_hand_position := Vector2.ZERO
var prediction_hand_scale := Vector2.ONE
var prediction_badge_positions: Dictionary = {}
var prediction_badge_scales: Dictionary = {}
var prediction_badge_pivots: Dictionary = {}
var prediction_players_revealed := false
const BOT_NAMES := ["", "Luca", "Sofia", "Marco", "Giulia", "Leo", "Emma", "Nico"]
# The turn order follows the visual order of the seats around the table.
const CLOCKWISE_SEATS := [0, 1, 2, 3, 4, 5, 6, 7]
# Player 0 is local; the other seats run from left to right around the table.
const SEAT_POSITIONS := [
	Vector2(40, 705),
	Vector2(45, 345),
	Vector2(245, 80),
	Vector2(550, 40),
	Vector2(850, 30),
	Vector2(1150, 40),
	Vector2(1450, 80),
	Vector2(1655, 345),
]

@onready var hand = $Parallax/Hand/HBoxContainer
@onready var table = $Parallax/PlayArea
@onready var pile = $Parallax/DeckPile

func _ready() -> void:
	if get_node("/root/NetworkSession").dedicated:
		set_process(false)
		return
	# Slightly enlarge only the player's hand; table cards and the deck keep
	# their existing proportions.
	hand.scale = Vector2.ONE * 1.7
	for data in Deck.new().cards:
		catalog[data.strength - 1] = data
	_build_ui()
	loading_screen = preload("res://scenes/balatro/scripts/loading_transition.gd").new()
	add_child(loading_screen)
	hand.play_requested.connect(func(card): _request_play.call_deferred(card))
	hand.rebuild(0)
	busy = false
	menu = MainMenu.new()
	game_ui.get_parent().add_child(menu)
	menu.start_requested.connect(_menu_start)
	pause_menu = preload("res://scenes/balatro/scripts/pause_menu.gd").new()
	add_child(pause_menu)
	pause_menu.setup(self)
	var throw_objects = preload("res://scenes/balatro/scripts/throw_objects.gd").new()
	game_ui.add_child(throw_objects)
	throw_objects.setup(self)
	var pause_button: Button = menu._button(game_ui, "||", pause_menu.open)
	pause_button.position = Vector2(28, 24)
	pause_button.custom_minimum_size = Vector2(80, 64)
	pause_button.size = Vector2(80, 64)
	pause_button.z_index = 200
	var card_info = preload("res://scenes/balatro/scripts/card_info.gd").new()
	add_child(card_info)
	card_info.setup(self)
	var info_button: Button = menu._button(game_ui, "INFO", card_info.open)
	info_button.custom_minimum_size = Vector2(150, 64)
	info_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	info_button.offset_left = -178
	info_button.offset_right = -28
	info_button.offset_top = 24
	info_button.offset_bottom = 88
	info_button.z_index = 200
	var voice = get_node("/root/VoiceChat")
	var voice_button: Button = menu._button(game_ui, "VOCE", voice.open_panel)
	voice_button.custom_minimum_size = Vector2(150, 64)
	voice_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	voice_button.offset_left = -178
	voice_button.offset_right = -28
	voice_button.offset_top = 104
	voice_button.offset_bottom = 168
	voice_button.z_index = 200
	voice_button.tooltip_text = "Attiva la chat vocale e regola i volumi dei giocatori"
	voice.changed.connect(func():
		voice_button.text = "VOCE OFF" if not voice.enabled else ("MUTO" if voice.muted else "VOCE ON")
	)
	game_ui.visibility_changed.connect(func():
		$GameBackground.set_in_game(game_ui.visible)
		voice_button.visible = online
		if not game_ui.visible:
			voice._call("closePanel")
	)
	$GameBackground.set_in_game(game_ui.visible)
	overlay = GameOverlay.new()
	game_ui.get_parent().add_child(overlay)
	overlay.replay_requested.connect(func():
		if online:
			busy = true
			online_match.action({"op": "restart"})
		else:
			_start(player_count)
	)
	overlay.menu_requested.connect(_show_menu)
	overlay.prediction_question_started.connect(func():
		if rules.hand_size > 1:
			_hide_predicted_players()
	)
	overlay.prediction_banner_cleared.connect(func():
		if rules.phase == "prediction" and rules.current == 0:
			if rules.hand_size == 1:
				_reveal_prediction_buttons()
			else:
				_reveal_prediction_players()
	)
	_show_menu()
	var net = get_node("/root/NetworkSession")
	net.avatars_changed.connect(_refresh_profile_photos)
	online_match.setup(self, net)
	net.updated.connect(func(state):
		if state.stage != "lobby":
			if not online:
				_clear(scores)
				pile.place_home()
			online = true
			online_match.receive(state)
	)
	net.clock_updated.connect(func(seconds):
		if online:
			turn_clock.text = "%d" % ceili(seconds)
			turn_clock.visible = seconds >= 0 and not busy and rules.current == 0
	)
	net.connection_lost.connect(func():
		if online:
			busy = true
			hand.allow_play = false
			turn_clock.text = "Riconnessione…"
			turn_clock.show()
	)
	net.problem.connect(func(message):
		if online:
			turn_clock.text = message
			turn_clock.show()
	)
	if get_tree().has_meta("bisca_restart"):
		var restart: Dictionary = get_tree().get_meta("bisca_restart")
		get_tree().remove_meta("bisca_restart")
		_menu_start.call_deferred(restart.name, restart.count)

func _show_menu() -> void:
	local_bot_generation += 1
	presented_damage_round = -1
	if online:
		get_node("/root/NetworkSession").leave()
		online = false
		online_match.queue.clear()
		online_match.round_seen = -1
		online_match.damage_seen = -1
		online_match.trick_seen = ""
	for button in overlay.buttons.get_children():
		button.show()
	timed_turn = ""
	turn_time_left = 0.0
	turn_clock.hide()
	overlay.hide()
	game_ui.hide()
	$Parallax.hide()
	menu.show()
	menu.show_home()

func _menu_start(display_name: String, count: int) -> void:
	local_name = display_name
	rules.configure(menu.match_options.values())
	rules.force_local_joker = false
	_start(count)

func _name_of(id: int) -> String:
	if online and id >= 0 and id < online_match.names.size():
		return online_match.names[id]
	return local_name if id == 0 else BOT_NAMES[id]

func _refresh_profile_photos() -> void:
	var net = get_node("/root/NetworkSession")
	for id in range(scores.get_child_count()):
		var badge = scores.get_child(id)
		badge.profile_texture = net.avatar_for_slot((id + online_match.local_id) % player_count) if online else (menu.profile_texture if id == 0 else null)
		badge.queue_redraw()

func _label(parent: Node, text: String, font_size: int = 24) -> MixedLabel:
	var label := MixedLabel.new()
	label.set_mixed_text(text)
	label.add_theme_font_size_override("normal_font_size", font_size)
	label.add_theme_font_override("normal_font", KIDS_FONT)
	label.add_theme_color_override("default_color", Color("153536"))
	label.add_theme_color_override("font_color", Color("153536"))
	parent.add_child(label)
	return label

func _box(parent: Node, position_value: Vector2, size_value: Vector2, horizontal: bool = true) -> BoxContainer:
	var box: BoxContainer = HBoxContainer.new() if horizontal else VBoxContainer.new()
	parent.add_child(box)
	box.position = position_value
	box.size = size_value
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	return box

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui := Control.new()
	game_ui = ui
	layer.add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	turn_clock = Label.new()
	ui.add_child(turn_clock)
	# Updated from the hand's layout, including its scale and canvas transform.
	turn_clock.size = Vector2(180, 50)
	turn_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	turn_clock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	turn_clock.z_index = 100
	turn_clock.add_theme_font_override("font", KIDS_FONT)
	turn_clock.add_theme_font_size_override("font_size", 28)
	turn_clock.add_theme_color_override("font_color", Color("fff0cc"))
	turn_clock.hide()
	status = _label(ui, "", 28)
	status.position = Vector2(100, 8)
	status.size = Vector2(1720, 52)
	# La logica continua a usare status internamente, ma il testo di commento
	# in cima allo schermo resta nascosto durante la partita.
	status.hide()
	scores = Control.new()
	ui.add_child(scores)
	scores.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scores.z_index = 21
	scores.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_shade = ColorRect.new()
	ui.add_child(damage_shade)
	damage_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage_shade.color = Color(0.082353, 0.207843, 0.211765, 0.65)
	damage_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_shade.z_index = 20
	damage_shade.hide()
	joker_cancel_area = Control.new()
	ui.add_child(joker_cancel_area)
	joker_cancel_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	joker_cancel_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joker_cancel_area.z_index = 10
	joker_cancel_area.gui_input.connect(_on_joker_cancel_input)
	# Keep predictions and joker choices beside the playable area, instead of
	# pushing them to the bottom edge of the screen.
	actions = _box(ui, Vector2(260, 625), Vector2(1400, 64))
	actions.z_index = 11
	result_panel = PanelContainer.new()
	ui.add_child(result_panel)
	result_panel.position = Vector2(420, 365)
	result_panel.custom_minimum_size = Vector2(1080, 280)
	results = _label(result_panel, "", 25)
	result_panel.hide()

func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func _button(text: String, callback: Callable, enabled: bool = true) -> Button:
	var button := RoundedSquareButton.new()
	button.text = text.to_upper()
	button.custom_minimum_size = Vector2(112, 60)
	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_font_override("font", KIDS_FONT)
	button.add_theme_stylebox_override("normal", _action_button_style(BUTTON_PURPLE))
	button.add_theme_stylebox_override("hover", _action_button_style(BUTTON_CYAN, BUTTON_TEXT, 6))
	button.add_theme_stylebox_override("pressed", _action_button_style(BUTTON_PURPLE_PRESSED, BUTTON_TEXT, 2))
	button.add_theme_stylebox_override("disabled", _action_button_style(BUTTON_DISABLED))
	button.add_theme_color_override("font_color", BUTTON_TEXT)
	button.add_theme_color_override("font_hover_color", BUTTON_TEXT)
	button.add_theme_color_override("font_pressed_color", BUTTON_TEXT)
	button.add_theme_color_override("font_disabled_color", LexispellStyle.DISABLED_TEXT)
	button.disabled = not enabled
	button.pressed.connect(callback)
	actions.add_child(button)
	return button

func _hold_button(text: String, callback: Callable) -> void:
	_hold_button_in(text, callback, actions)

func _hold_button_in(text: String, callback: Callable, parent: Node) -> HoldButton:
	var button := HoldButton.new()
	button.caption = text.to_upper()
	button.custom_minimum_size = Vector2(250, 90)
	button.hold_duration = 0.75
	button.base_color = BUTTON_PURPLE
	button.fill_color = Color("347667")
	button.confirm_progress_color = BUTTON_CYAN
	button.font = KIDS_FONT
	button.font_size = 24
	button.corner_radius = JOKER_BUTTON_RADIUS
	parent.add_child(button)
	button.hold_completed.connect(callback)
	return button

func _action_button_style(color: Color, border_color: Color = Color.TRANSPARENT, border_width: int = 0) -> StyleBoxFlat:
	return LexispellStyle.button_style(color, border_color, border_width)

func _start(count: int) -> void:
	presented_damage_round = -1
	if busy:
		return
	local_bot_generation += 1
	busy = true
	await loading_screen.cover()
	timed_turn = ""
	menu.hide()
	overlay.hide()
	last_turn_notice = ""
	game_ui.show()
	$Parallax.show()
	player_count = count
	var seating: Array = CLOCKWISE_SEATS.filter(func(id): return id < count)
	rules.start(count, -1, seating)
	pile.place_home()
	displayed_taken.clear()
	_clear(scores)
	for id in range(count):
		displayed_taken[id] = 0
	_clear_table()
	hand.rebuild(0)
	_refresh()
	await loading_screen.uncover()
	_deal_round()

func _clear_table() -> void:
	table.clear_throws()
	if table.layout_tween and table.layout_tween.is_running():
		table.layout_tween.kill()
	table.cards.clear()
	table_visuals.clear()
	_clear(table)

func _deal_round() -> void:
	busy = true
	# Reset the presentation counters too, before the first UI refresh.
	displayed_taken.clear()
	for player in rules.players:
		displayed_taken[player.id] = player.taken
	pending_joker = null
	hand.allow_play = false
	_clear_table()
	result_panel.hide()
	var own: Array = rules.view_for(0).players[0].hand
	hand.conceal_hand = rules.hand_size == 1
	if rules.hand_size == 1:
		hand.rebuild(0)
		_refresh()
		status.set_mixed_text("Una carta · Preparazione del tavolo…")
		if not own.is_empty():
			pile.card_count = 40
			await get_tree().create_timer(1.0, false).timeout
			await pile.prepare_deal()
		_place_blind_cards(not own.is_empty())
		pile.card_count = rules.remaining_deck.size()
		if not own.is_empty():
			await get_tree().create_timer(0.4, false).timeout
			await pile.return_home()
		busy = false
		_drive()
		return
	hand.rebuild(own.size())
	var delivery = Deck.new()
	delivery.cards.clear()
	# Back-only placeholders contain no private card value in the blind round.
	for id in own:
		if id < 0:
			var hidden = preload("res://scenes/balatro/scripts/card_data.gd").new()
			hidden.texture = BACK
			delivery.cards.append(hidden)
		else:
			delivery.cards.append(catalog[id])
	delivery.cards.reverse()
	_refresh()
	status.set_mixed_text("%d carte · Distribuzione…" % rules.hand_size)
	if not own.is_empty():
		await hand.deal_from(delivery, pile, rules.active_ids().size(), true)
	pile.card_count = rules.remaining_deck.size()
	busy = false
	_drive()

func _place_blind_cards(animate_own: bool) -> void:
	for p in rules.view_for(0).players:
		if not p.active:
			continue
		var card = CardScene.instantiate()
		add_child(card)
		if p.id == 0:
			var hidden = preload("res://scenes/balatro/scripts/card_data.gd").new()
			hidden.texture = BACK
			card.set_card_data(hidden)
			card.set_face_down(true)
		else:
			card.set_card_data(catalog[p.hand[0]])
		card.set_meta("seat_id", p.id)
		card.global_position = pile.top_global_position()
		table.play_card(card, animate_own and p.id == 0)
		table_visuals[p.id] = card
	_refresh_winning_card()

func _animate_round_damage() -> void:
	status.set_mixed_text("Fine round · Vite perse")
	var damaged_badges: Array[Control] = []
	var original_positions: Dictionary = {}
	var original_scales: Dictionary = {}
	for result in rules.round_result:
		if result.loss <= 0:
			continue
		var badge := scores.get_child(result.player) as Control
		if not is_instance_valid(badge):
			continue
		damaged_badges.append(badge)
		original_positions[badge] = badge.position
		original_scales[badge] = badge.scale
	if not damaged_badges.is_empty():
		# Pause briefly after the last trick before starting the life-loss scene.
		await get_tree().create_timer(1.0, false).timeout
		# Put all player badges under the shade. The damaged badges receive a
		# higher z-index below and remain clearly visible in the center row.
		scores.z_index = 19
		damage_shade.modulate.a = 0.0
		damage_shade.show()
		var shade_tween := create_tween()
		shade_tween.tween_property(damage_shade, "modulate:a", 1.0, 0.18)
		await shade_tween.finished
		var viewport_size := get_viewport_rect().size
		# Calculate the row from the real rendered widths. Using a fixed
		# top-left offset made badges with different scales appear misaligned.
		# Every target center now shares exactly the same Y coordinate.
		var row_gap := 28.0
		var row_width := 0.0
		for badge in damaged_badges:
			var rendered_size: Vector2 = badge.size * badge.scale
			row_width += rendered_size.x
		row_width += row_gap * float(maxi(0, damaged_badges.size() - 1))
		var row_x := (viewport_size.x - row_width) / 2.0
		var row_center_y := viewport_size.y / 2.0
		var gather := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		for index in range(damaged_badges.size()):
			var badge := damaged_badges[index]
			badge.z_index = 100 + index
			var target_size: Vector2 = badge.size * badge.scale
			var target_position := Vector2(row_x, row_center_y - target_size.y / 2.0)
			gather.tween_property(badge, "position", target_position, 0.55)
			gather.tween_property(badge, "rotation", 0.0, 0.35)
			row_x += target_size.x + row_gap
		await gather.finished
		await get_tree().create_timer(0.5, false).timeout
	var pending := {"count": 0}
	presented_damage_round = rules.round_number
	for result in rules.round_result:
		if int(result.loss) <= 0:
			continue
		var badge = scores.get_child(result.player)
		pending.count += 1
		badge.life_animation_finished.connect(func(): pending.count -= 1, CONNECT_ONE_SHOT)
		badge.animate_life_change(result.previous_lives, result.loss, result.lives, true)
	while pending.count > 0:
		await get_tree().process_frame
	if not damaged_badges.is_empty():
		await get_tree().create_timer(1.5, false).timeout
		var return_tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
		for badge in damaged_badges:
			return_tween.tween_property(badge, "position", original_positions[badge], 0.55)
			return_tween.tween_property(badge, "scale", original_scales[badge], 0.45)
			return_tween.tween_property(badge, "rotation", 0.0, 0.35)
		await return_tween.finished
		for badge in damaged_badges:
			badge.finish_damage_return()
			badge.z_index = 0
		scores.z_index = 21
		var shade_out := create_tween()
		shade_out.tween_property(damage_shade, "modulate:a", 0.0, 0.2)
		await shade_out.finished
		damage_shade.hide()

func _refresh() -> void:
	_clear(actions)
	actions.position.y = 550.0 if rules.phase == "prediction" else 630.0
	joker_buttons.clear()
	joker_cancel_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var view: Dictionary = rules.view_for(0)
	for p in view.players:
		var badge: Control
		if p.id < scores.get_child_count():
			badge = scores.get_child(p.id)
		else:
			badge = PlayerBadge.new()
			scores.add_child(badge)
		# During the prediction reveal, the sequence owns the opponents'
		# positions. A refresh must not move a visible/revealing badge back to
		# its seat for one frame.
		if not prediction_focus or p.id == 0:
			badge.position = SEAT_POSITIONS[p.id]
		if not prediction_focus:
			badge.modulate.a = 1.0
		var badge_scale := 1.5 if p.id == 0 else 1.35
		if not prediction_focus or p.id == 0:
			badge.scale = Vector2.ONE * badge_scale
		var presentation_modulate := badge.modulate
		var visible_lives: int = p.lives
		var visible_out: bool = not p.active
		if presented_damage_round != rules.round_number:
			for result in rules.round_result:
				if result.player == p.id and result.loss > 0:
					visible_lives = result.previous_lives
					visible_out = visible_lives <= 0
		badge.configure(_name_of(p.id), visible_lives, p.bid, displayed_taken.get(p.id, p.taken), rules.current == p.id, visible_out, rules.phase in ["play", "trick_complete"])
		badge.profile_texture = get_node("/root/NetworkSession").avatar_for_slot((p.id + online_match.local_id) % player_count) if online else (menu.profile_texture if p.id == 0 else null)
		# configure() resets opacity for normal/eliminated seats. During this
		# sequence opacity belongs to the exit/reveal tween, including its delays.
		if prediction_focus and p.id != 0:
			badge.modulate = presentation_modulate
	if rules.phase == "prediction" and rules.current == 0:
		_set_prediction_layers(rules.hand_size > 1)
	else:
		_set_prediction_layers(false)
	var heading := "%d carte · " % rules.hand_size
	if rules.phase == "prediction":
		status.set_mixed_text(heading + "Predizione di %s" % _name_of(rules.current))
		if rules.hand_size == 1:
			status.set_mixed_text(heading + "Predizione di %s\nLa tua carta resta nascosta fino alla fine della presa" % _name_of(rules.current))
		if rules.current == 0 and not busy:
			_label(actions, "Quante prese farai?", 22)
			for bid in range(rules.hand_size + 1):
				var caption := str(bid)
				if rules.hand_size == 1:
					caption = "Perdo" if bid == 0 else "Vinco"
				var prediction_button := _button(caption, _predict.bind(bid), rules.legal_bids(0).has(bid))
				prediction_button.custom_minimum_size.y = 80
				prediction_button.pivot_offset = prediction_button.size / 2.0
				prediction_button.scale = Vector2.ONE * 0.72
				prediction_button.rotation_degrees = 5.0 * [-1.0, 1.0].pick_random()
				prediction_button.modulate.a = 0.0
			if rules.legal_bids(0).size() < rules.hand_size + 1:
				_label(actions, "Il totale non può essere %d" % rules.hand_size, 20)
	elif rules.phase == "play":
		status.set_mixed_text(heading + "Tocca a %s" % _name_of(rules.current))
		if rules.current == 0 and not busy:
			if pending_joker:
				joker_cancel_area.mouse_filter = Control.MOUSE_FILTER_STOP
				_label(actions, "Come giochi il jolly?", 22)
				var joker_row := HBoxContainer.new()
				actions.add_child(joker_row)
				joker_row.alignment = BoxContainer.ALIGNMENT_CENTER
				joker_row.add_theme_constant_override("separation", 48)
				var low_button := _hold_button_in("PIU' BASSA", _on_joker_hold_completed.bind(false), joker_row)
				var high_button := _hold_button_in("PIU' ALTA", _on_joker_hold_completed.bind(true), joker_row)
				joker_buttons = [low_button, high_button]
			else:
				_label(actions, "Trascina una carta al centro per giocarla", 22)
	elif rules.phase == "trick_complete":
		status.set_mixed_text(heading + "%s vince la presa" % _name_of(rules.last_winner))
	elif rules.phase in ["round_complete", "finished"]:
		status.set_mixed_text(heading + ("Fine round" if rules.phase == "round_complete" else "%s vince la partita!" % _name_of(rules.winner)))
	if not rules.players[0].active and rules.phase not in ["finished", "round_complete"]:
		status.set_mixed_text("%s\nSei eliminato: puoi seguire la partita" % status.text)
	hand.allow_play = rules.phase == "play" and rules.hand_size > 1 and rules.current == 0 and not busy and pending_joker == null

func _position_turn_clock() -> void:
	if not is_instance_valid(turn_clock) or not is_instance_valid(hand) or hand.cards.is_empty():
		return
	# Use the resting slot, so dragging/hovering a card cannot move the timer.
	var edge: Vector2 = hand._slot_position(0) + Vector2(0, hand.cards[0].size.y / 2.0)
	var canvas_point: Vector2 = hand.get_global_transform_with_canvas() * edge
	var ui_point: Vector2 = game_ui.get_global_transform_with_canvas().affine_inverse() * canvas_point
	turn_clock.position = ui_point - Vector2(turn_clock.size.x + 30.0, turn_clock.size.y / 0.8)

func _process(delta: float) -> void:
	_position_turn_clock()
	if online:
		return
	if not is_instance_valid(turn_clock):
		return
	var waiting: bool = not busy and game_ui.visible and rules.current == 0 and rules.phase in ["prediction", "play"]
	if not waiting:
		turn_clock.hide()
		return
	var key := "%d:%s:%d" % [rules.round_number, rules.phase, rules.completed_tricks]
	if timed_turn != key:
		timed_turn = key
		turn_time_left = TURN_SECONDS
	turn_time_left = maxf(0.0, turn_time_left - delta)
	turn_clock.text = "%d" % ceili(turn_time_left)
	turn_clock.show()
	if turn_time_left <= 0.0:
		turn_clock.hide()
		if rules.phase == "prediction":
			var bids: Array = rules.legal_bids(0)
			if not bids.is_empty():
				_predict(bids.pick_random())
		elif pending_joker:
			_on_joker_hold_completed(randf() < 0.5)
		elif not hand.cards.is_empty():
			_play_human(hand.cards.pick_random(), randf() < 0.5)

func _predict(bid: int) -> void:
	if online:
		if busy:
			return
		var revision: int = online_match.state.rev
		busy = true
		await _hide_predicted_players()
		await _hide_prediction_buttons(bid)
		await _exit_prediction_focus()
		await overlay.dismiss_prediction_turn()
		online_match.action({"op": "predict", "bid": bid, "rev": revision})
		return
	if busy or not rules.predict(0, bid):
		return
	busy = true
	await _hide_predicted_players()
	await _hide_prediction_buttons(bid)
	await _exit_prediction_focus()
	await overlay.dismiss_prediction_turn()
	busy = false
	_drive()

func _hide_prediction_buttons(bid: int) -> void:
	var selected: Control
	var others: Array[Control] = []
	var selected_caption := ("PERDO" if bid == 0 else "VINCO") if rules.hand_size == 1 else str(bid)
	for child in actions.get_children():
		if not child is Button:
			continue
		var button := child as Control
		if button.name == selected_caption or (child as Button).text == selected_caption:
			selected = button
		else:
			others.append(button)
	for button in others:
		var fade_other := button.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		fade_other.set_parallel(true)
		fade_other.tween_property(button, "scale:x", 0.72, 0.18)
		fade_other.tween_property(button, "scale:y", 0.72, 0.18)
		fade_other.tween_property(button, "rotation_degrees", 5.0 * [-1.0, 1.0].pick_random(), 0.1)
		fade_other.tween_property(button, "modulate:a", 0.0, 0.14)
	if not others.is_empty():
		await get_tree().create_timer(0.14, false).timeout
	if is_instance_valid(selected):
		var fade_selected := selected.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		fade_selected.set_parallel(true)
		fade_selected.tween_property(selected, "scale:x", 0.72, 0.2)
		fade_selected.tween_property(selected, "scale:y", 0.72, 0.2)
		fade_selected.tween_property(selected, "rotation_degrees", 5.0 * [-1.0, 1.0].pick_random(), 0.1)
		fade_selected.tween_property(selected, "modulate:a", 0.0, 0.18)
		await fade_selected.finished
	var text_elements: Array[Control] = []
	for child in actions.get_children():
		if child is Control and not child is Button:
			text_elements.append(child as Control)
	for element in text_elements:
		var fade_text := element.create_tween()
		fade_text.tween_property(element, "modulate:a", 0.0, 0.12)
	if not text_elements.is_empty():
		await get_tree().create_timer(0.12, false).timeout

# Profiles stay at their table seats throughout the prediction presentation.
func _hide_predicted_players() -> void:
	pass

func _set_prediction_layers(active: bool) -> void:
	prediction_focus = false
	scores.z_index = 30 if active else 21
	actions.z_index = 31 if active else 11
	for badge in scores.get_children():
		badge._update_elimination_tint()

func _exit_prediction_focus() -> void:
	_set_prediction_layers(false)

func _reveal_prediction_players() -> void:
	_reveal_prediction_buttons()

func _reveal_prediction_buttons() -> void:
	await get_tree().create_timer(0.1, false).timeout
	GameAudio.play(self, GameAudio.NOTICE, -14.0)
	var reveal_all := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for child in actions.get_children():
		if not child is Button:
			continue
		var button := child as Control
		if not is_instance_valid(button):
			continue
		reveal_all.tween_property(button, "scale:x", 1.0, 0.2)
		reveal_all.tween_property(button, "scale:y", 1.0, 0.35)
		reveal_all.tween_property(button, "rotation_degrees", 0.0, 0.1).set_delay(0.1)
		reveal_all.tween_property(button, "modulate:a", 1.0, 0.2)

func _request_play(card: Control) -> void:
	if busy or rules.phase != "play" or rules.current != 0 or pending_joker:
		return
	if rules.hand_size > 1 and card.data.strength - 1 == Rules.JOKER:
		pending_joker = card
		hand.commit_card(card, true)
		table_visuals[0] = card
		_refresh()
	else:
		_play_human(card, true)

func _cancel_joker() -> void:
	if pending_joker and pending_joker.is_played:
		table_visuals.erase(0)
		hand.return_card(pending_joker)
	pending_joker = null
	_refresh()

func _on_joker_hold_completed(high: bool) -> void:
	if busy or not pending_joker or joker_buttons.size() != 2:
		return
	busy = true
	hand.allow_play = false
	joker_cancel_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var selected: Control = joker_buttons[1] if high else joker_buttons[0]
	var other: Control = joker_buttons[0] if high else joker_buttons[1]
	for button in joker_buttons:
		button.lock_interaction()
	if selected.confirming:
		await selected.confirmation_finished
	await _hide_joker_button(other)
	await _hide_joker_button(selected)
	var card = pending_joker
	busy = false
	_play_human(card, high)

func _hide_joker_button(button: Control) -> void:
	if not is_instance_valid(button):
		return
	button.stop_visual_tweens()
	var animation := button.create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	animation.set_parallel(true)
	animation.tween_property(button, "modulate:a", 0.0, 0.18)
	animation.tween_property(button, "scale", Vector2.ONE * 0.72, 0.18)
	await animation.finished
	button.hide()

func _on_joker_cancel_input(event: InputEvent) -> void:
	if not pending_joker:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_cancel_joker()
		joker_cancel_area.accept_event()

func _play_human(card: Control, high: bool) -> void:
	if busy:
		return
	if online:
		busy = true
		hand.allow_play = false
		online_match.action({"op": "play", "card": card.data.strength - 1, "high": high})
		return
	var is_joker: bool = card.data.strength - 1 == Rules.JOKER
	var index: int = 0 if rules.hand_size == 1 else rules.players[0].hand.find(card.data.strength - 1)
	if not rules.play(0, index, high):
		return
	pending_joker = null
	card.set_meta("seat_id", 0)
	if not card.is_played:
		hand.commit_card(card)
	table_visuals[0] = card
	_refresh_winning_card()
	if is_joker:
		busy = true
		await overlay.announce_joker(high)
		busy = false
	_drive()

func _show_bot_card(id: int) -> void:
	var entry: Dictionary = rules.trick.back()
	var card = CardScene.instantiate()
	add_child(card)
	card.set_card_data(catalog[entry.card])
	var badge = scores.get_child(id)
	card.global_position = badge.global_position + Vector2(80, 128) * badge.scale - card.size / 2.0
	card.set_meta("seat_id", id)
	card.rotation = table.landing_rotation(card)
	card.scale = Vector2.ONE * 0.5
	table.play_card(card)
	table_visuals[id] = card
	_refresh_winning_card()

func _refresh_winning_card() -> void:
	if rules.trick.is_empty():
		table.set_winning_card(null)
		return
	var best: Dictionary = rules.trick[0]
	for entry in rules.trick:
		if entry.card == Rules.JOKER and table_visuals.has(entry.player):
			table_visuals[entry.player].show_joker_direction(entry.strength == 41)
		if entry.strength > best.strength:
			best = entry
	table.set_winning_card(table_visuals.get(best.player))

func _animate_trick_capture() -> void:
	var winner_id: int = rules.last_winner
	if winner_id < 0 or table_visuals.is_empty():
		return
	var winner_card: Control = table_visuals.get(winner_id)
	if not is_instance_valid(winner_card):
		return
	var winner_center := winner_card.global_position + winner_card.size / 2.0
	var ordered_cards: Array[Control] = []
	for entry in rules.trick:
		var card: Control = table_visuals.get(entry.player)
		if is_instance_valid(card) and card != winner_card:
			ordered_cards.append(card)
	# First collapse all losing cards underneath the winning card.
	GameAudio.play(self, GameAudio.SWIPE, -14.0)
	var grouping := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	for index in range(ordered_cards.size()):
		var card := ordered_cards[index]
		card.z_index = 20 + index
		grouping.tween_property(card, "global_position", winner_center - card.size / 2.0 + Vector2(0, 11 + index * 4), 0.42)
		grouping.tween_property(card, "rotation", winner_card.rotation + (index - 1) * 0.035, 0.42)
		grouping.tween_property(card, "scale", Vector2.ONE * 0.70, 0.42)
	winner_card.z_index = 60
	await grouping.finished
	# Then the complete stack flies to the winner's player badge.
	GameAudio.play(self, GameAudio.SWIPE, -12.0)
	var badge = scores.get_child(winner_id)
	var destination: Vector2 = badge.global_position + Vector2(80, 128) * badge.scale
	var capture := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	for index in range(ordered_cards.size()):
		var card := ordered_cards[index]
		capture.tween_property(card, "global_position", destination - card.size / 2.0 + Vector2(0, index * 2), 0.48)
		capture.tween_property(card, "scale", Vector2.ONE * 0.18, 0.48)
		capture.tween_property(card, "rotation", winner_card.rotation, 0.48)
	capture.tween_property(winner_card, "global_position", destination - winner_card.size / 2.0, 0.48)
	capture.tween_property(winner_card, "scale", Vector2.ONE * 0.18, 0.48)
	await capture.finished
	for card in table_visuals.values():
		if is_instance_valid(card):
			card.queue_free()
	table.cards.clear()
	table_visuals.clear()
	displayed_taken[winner_id] = rules.players[winner_id].taken

func _local_bot_is_current(generation: int) -> bool:
	return is_inside_tree() and local_bot_generation == generation and not online and game_ui.visible

func _drive() -> void:
	if online:
		return
	if busy:
		return
	busy = true
	while true:
		_refresh()
		if rules.hand_size == 1 and rules.phase == "play":
			status.set_mixed_text("Predizioni complete · Rivelazione delle carte")
			await get_tree().create_timer(0.65, false).timeout
			while rules.phase == "play":
				var actor: int = rules.current
				var card_id: int = rules.players[actor].hand[0]
				var joker_high: bool = rules.players[actor].bid == 1
				rules.play(actor, 0)
				_refresh_winning_card()
				if card_id == Rules.JOKER:
					await overlay.announce_joker(joker_high)
			continue
		if rules.phase == "trick_complete":
			for entry in rules.trick:
				var card = table_visuals[entry.player]
				card.set_card_data(catalog[entry.card])
				card.set_face_down(false)
				if entry.card == Rules.JOKER:
					card.show_joker_direction(entry.strength == 41)
					card.tooltip_text = "Jolly · " + ("PIU' ALTA" if entry.strength == 41 else "PIU' BASSA")
			await get_tree().create_timer(0.75, false).timeout
			await _animate_trick_capture()
			rules.advance_trick()
			if rules.phase in ["round_complete", "finished"]:
				# Mostra subito l'ultima presa nel contatore prima della scena
				# della perdita vite; _animate_round_damage attende poi 1 secondo.
				_refresh()
				await _animate_round_damage()
			if rules.phase == "round_complete":
				rules.begin_round()
				await _deal_round()
				return
			if rules.phase == "play":
				_clear_table()
			continue
		if rules.phase == "finished":
			busy = false
			_refresh()
			overlay.show_victory(_name_of(rules.winner))
			return
		if rules.current == 0 and rules.phase == "prediction":
			var notice := "%d:%s:%d" % [rules.round_number, rules.phase, rules.completed_tricks]
			if notice != last_turn_notice:
				last_turn_notice = notice
				await overlay.announce_turn(true, rules.hand_size == 1)
		if rules.phase == "round_complete" or rules.current == 0:
			busy = false
			_refresh()
			return
		var id: int = rules.current
		var bot_delay := LOCAL_BOT_PREDICTION_DELAY if rules.phase == "prediction" else LOCAL_BOT_PLAY_DELAY
		await get_tree().create_timer(bot_delay, false).timeout
		# Bots only consume their own redacted view, never another hand.
		var view: Dictionary = rules.view_for(id)
		var generation := local_bot_generation
		var valid := _local_bot_is_current.bind(generation)
		var decision: Dictionary = await bot_policy.decide(view, id, get_tree(), valid)
		if decision.is_empty() or not valid.call():
			busy = false
			return
		if rules.phase == "prediction":
			rules.predict(id, decision.bid)
		else:
			var own: Dictionary = view.players[id]
			var index: int = decision.index
			var played_id: int = own.hand[index]
			var joker_high: bool = decision.high
			rules.play(id, index, joker_high)
			_show_bot_card(id)
			if played_id == Rules.JOKER:
				await overlay.announce_joker(joker_high)

func _next_round() -> void:
	if not busy and rules.begin_round():
		_deal_round()
