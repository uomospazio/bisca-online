extends RefCounted

var host: Control
var net: Node
var queue: Array[Dictionary] = []
var processing := false
var state: Dictionary = {}
var names: Array[String] = []
var round_seen := -1
var trick_seen := ""
var damage_seen := -1
var local_id := 0
var joker_seen_round := -1

func setup(controller: Control, session: Node) -> void:
	host = controller
	net = session

func receive(value: Dictionary) -> void:
	queue.append(value.duplicate(true))
	if not processing:
		_drain()

func seat(id: int, count: int) -> int:
	return -1 if id < 0 else (id - local_id + count) % count

func _drain() -> void:
	processing = true
	while not queue.is_empty() and host.online:
		await _apply(queue.pop_front())
	processing = false

func _apply(value: Dictionary) -> void:
	var entering_match: bool = host.menu.visible or (value.stage == "deal" and host.rules.phase == "finished")
	if entering_match:
		host.busy = true
		await host.loading_screen.cover()
	state = value
	local_id = value.you
	var count: int = value.players.size()
	var players: Array[Dictionary] = []
	players.resize(count)
	names.resize(count)
	for p in value.players:
		var copy: Dictionary = p.duplicate(true)
		copy.id = seat(p.id, count)
		players[copy.id] = copy
		names[copy.id] = value.people[p.id].name
	host.busy = true
	host.menu.hide()
	host.game_ui.show()
	host.get_node("Parallax").show()
	host.player_count = count
	host.rules.players = players
	host.rules.phase = value.phase
	host.rules.current = seat(value.current, count)
	host.rules.hand_size = value.hand_size
	host.rules.round_number = value.round
	host.rules.completed_tricks = value.completed_tricks
	host.rules.last_winner = seat(value.last_winner, count)
	host.rules.winner = seat(value.winner, count)
	host.rules.trick.clear()
	for entry in value.trick:
		var copy: Dictionary = entry.duplicate(true)
		copy.player = seat(entry.player, count)
		host.rules.trick.append(copy)
	host.rules.round_result.clear()
	for entry in value.round_result:
		var copy: Dictionary = entry.duplicate(true)
		copy.player = seat(entry.player, count)
		host.rules.round_result.append(copy)
	host.rules.order.clear()
	for id in value.order:
		host.rules.order.append(seat(id, count))
	host.rules.seat_order.assign(range(count))
	host.rules.remaining_deck.resize(value.remaining)
	var new_round: bool = entering_match or round_seen != value.round
	if new_round:
		host.presented_damage_round = -1
		round_seen = value.round
		trick_seen = ""
		host.displayed_taken.clear()
		host._clear_table()
		joker_seen_round = -1
	for p in players:
		if new_round or not host.displayed_taken.has(p.id):
			host.displayed_taken[p.id] = p.taken
	# Damage is presented with the old life totals until the heart changes.
	if value.stage != "damage":
		host._refresh()
	elif host.scores.get_child_count() < count:
		host._refresh()
	if new_round and value.stage == "deal":
		if entering_match:
			host.overlay.hide()
			host.hand.rebuild(0)
			await host.loading_screen.uncover()
		await host._deal_round()
	elif entering_match:
		await host.loading_screen.uncover()
	if value.hand_size == 1 and host.table_visuals.is_empty() and value.phase in ["prediction", "play"]:
		for p in players:
			if not p.active:
				continue
			var id: int = p.hand[0] if not p.hand.is_empty() else -1
			for entry in host.rules.trick:
				if entry.player == p.id:
					id = entry.card
			var card = host.CardScene.instantiate()
			host.add_child(card)
			if id >= 0:
				card.set_card_data(host.catalog[id])
			card.set_face_down(id < 0)
			card.set_meta("seat_id", p.id)
			host.table.play_card(card, false)
			host.table_visuals[p.id] = card
	var capture_key := "%d:%d" % [value.round, value.completed_tricks]
	var already_collected: bool = (value.stage == "trick" and trick_seen == capture_key) or value.phase in ["round_complete", "finished"]
	var entries: Array = [] if already_collected else host.rules.trick
	var joker_high := false
	var announce_joker := false
	for entry in entries:
		if not host.table_visuals.has(entry.player):
			var card: Control
			var from_hand := false
			if entry.player == 0:
				for own_card in host.hand.cards:
					if own_card.data and own_card.data.strength - 1 == entry.card:
						card = own_card
			if card:
				from_hand = true
				card.set_meta("seat_id", entry.player)
				host.hand.commit_card(card)
			else:
				card = host.CardScene.instantiate()
				host.add_child(card)
				card.global_position = host.scores.get_child(entry.player).global_position + Vector2(80, 128) * host.scores.get_child(entry.player).scale - card.size / 2.0
			if entry.card >= 0:
				card.set_card_data(host.catalog[entry.card])
			else:
				card.set_face_down(true)
			card.set_meta("seat_id", entry.player)
			if not from_hand:
				host.table.play_card(card)
			host.table_visuals[entry.player] = card
		elif entry.card >= 0:
			var card = host.table_visuals[entry.player]
			card.set_card_data(host.catalog[entry.card])
			card.set_face_down(false)
		if entry.card == host.Rules.JOKER and entry.has("strength") and joker_seen_round != value.round:
			joker_seen_round = value.round
			announce_joker = true
			joker_high = entry.strength == 41
	_sync_hand(players[0].hand, value.hand_size == 1)
	if not host.rules.trick.is_empty() and value.hand_size > 1:
		host._refresh_winning_card()
	if announce_joker:
		await host.overlay.announce_joker(joker_high)
	if value.stage == "trick":
		var key := "%d:%d" % [value.round, value.completed_tricks]
		if trick_seen != key:
			trick_seen = key
			host._refresh_winning_card()
			await host.get_tree().create_timer(0.5).timeout
			await host._animate_trick_capture()
	if value.stage == "damage" and damage_seen != value.round:
		damage_seen = value.round
		await host._animate_round_damage()
	host.pending_joker = null
	host.busy = value.stage != "turn"
	host._refresh()
	if value.stage == "turn":
		host._play_turn_sound()
	if value.phase == "finished" and value.stage == "turn":
		host._show_victory()
	elif value.phase == "prediction" and host.rules.current == 0 and value.stage == "turn":
		await host.overlay.announce_turn(true, value.hand_size == 1)
	else:
		host.overlay.hide()
	host.hand.allow_play = value.stage == "turn" and value.phase == "play" and value.hand_size > 1 and host.rules.current == 0

func _sync_hand(ids: Array, blind: bool) -> void:
	var desired: Array = [] if blind else ids
	var current: Array = []
	for card in host.hand.cards:
		current.append(card.data.strength - 1 if card.data else -1)
	var sorted_current := current.duplicate()
	var sorted_desired := desired.duplicate()
	sorted_current.sort()
	sorted_desired.sort()
	if sorted_current == sorted_desired:
		return
	host.hand.rebuild(desired.size())
	for i in range(desired.size()):
		host.hand.cards[i].set_card_data(host.catalog[desired[i]])

func action(command: Dictionary) -> void:
	command["rev"] = command.get("rev", state.rev)
	net.send(command)
