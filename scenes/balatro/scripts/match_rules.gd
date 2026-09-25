extends RefCounted

# Authoritative rules only: no nodes, animations or access to the UI.
# Cards are IDs 0..39: bastoni 1..10, spade, coppe, denari. Asso di denari is ID 30.
const JOKER := 30
var rng := RandomNumberGenerator.new()
var players: Array[Dictionary] = []
var round_number := 0
var hand_size := 5
var starter := -1
var current := -1
var phase := "idle"
var order: Array[int] = []
var trick: Array[Dictionary] = []
var played_cards: Array[Dictionary] = []
var completed_tricks := 0
var last_winner := -1
var winner := -1
var remaining_deck: Array[int] = []
var round_result: Array[Dictionary] = []
var seat_order: Array[int] = []
var force_local_joker := false
var initial_lives := 3
var starting_cards := 5

func configure(options: Dictionary) -> void:
	initial_lives = clampi(int(options.get("lives", 3)), 1, 10)
	starting_cards = clampi(int(options.get("starting_cards", 5)), 1, 5)

func start(count: int, seed_value: int = -1, seating: Array = []) -> bool:
	if count < 2 or count > 8:
		return false
	if not seating.is_empty():
		if seating.size() != count:
			return false
		for id in range(count):
			if seating.count(id) != 1:
				return false
	seat_order.assign(range(count) if seating.is_empty() else seating)
	if seed_value < 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	players.clear()
	for id in range(count):
		players.append({"id": id, "lives": initial_lives, "active": true, "hand": [], "bid": -1, "taken": 0, "exact_predictions": 0, "rounds_played": 0, "total_taken": 0})
	round_number = 0
	starter = rng.randi_range(0, count - 1)
	winner = -1
	phase = "idle"
	return begin_round()

func active_ids() -> Array[int]:
	var ids: Array[int] = []
	for p in players:
		if p.active:
			ids.append(p.id)
	return ids

func _next_active(after: int) -> int:
	var seat := seat_order.find(after)
	for distance in range(1, seat_order.size() + 1):
		var id := seat_order[(seat + distance) % seat_order.size()]
		if players[id].active:
			return id
	return -1

func begin_round() -> bool:
	if phase not in ["idle", "round_complete"]:
		return false
	if round_number > 0:
		starter = _next_active(starter)
	round_number += 1
	hand_size = starting_cards - ((round_number - 1) % starting_cards)
	order.clear()
	var id := starter
	for _i in range(active_ids().size()):
		order.append(id)
		id = _next_active(id)
	remaining_deck.clear()
	for card in range(40):
		remaining_deck.append(card)
	for i in range(39, 0, -1):
		var j := rng.randi_range(0, i)
		var temp := remaining_deck[i]
		remaining_deck[i] = remaining_deck[j]
		remaining_deck[j] = temp
	for p in players:
		p.hand = []
		p.bid = -1
		p.taken = 0
	for _i in range(hand_size):
		for player in order:
			players[player].hand.append(remaining_deck.pop_back())
	if force_local_joker:
		_force_joker_for_local_player()
	trick.clear()
	round_result.clear()
	played_cards.clear()
	completed_tricks = 0
	last_winner = -1
	current = starter
	phase = "prediction"
	return true

func _force_joker_for_local_player() -> void:
	if players.is_empty() or players[0].hand.is_empty():
		return
	if players[0].hand.has(JOKER):
		return
	var local_card: int = players[0].hand[0]
	for player_id in range(1, players.size()):
		var other_index: int = int(players[player_id].hand.find(JOKER))
		if other_index >= 0:
			players[0].hand[0] = JOKER
			players[player_id].hand[other_index] = local_card
			return
	var deck_index := remaining_deck.find(JOKER)
	if deck_index >= 0:
		players[0].hand[0] = JOKER
		remaining_deck[deck_index] = local_card

func legal_bids(player: int) -> Array[int]:
	var bids: Array[int] = []
	if phase != "prediction" or player != current:
		return bids
	var total := 0
	for id in order:
		if players[id].bid >= 0:
			total += int(players[id].bid)
	for bid in range(hand_size + 1):
		if player != order.back() or total + bid != hand_size:
			bids.append(bid)
	return bids

func predict(player: int, bid: int) -> bool:
	if not legal_bids(player).has(bid):
		return false
	players[player].bid = bid
	if player == order.back():
		phase = "play"
		current = starter
	else:
		current = _next_active(player)
	return true

func play(player: int, hand_index: int, joker_high: bool = true) -> bool:
	if phase != "play" or player != current:
		return false
	if hand_index < 0 or hand_index >= players[player].hand.size():
		return false
	var card: int = players[player].hand[hand_index]
	if hand_size == 1:
		joker_high = players[player].bid == 1
	var strength := card + 1
	if card == JOKER:
		strength = 41 if joker_high else 0
	players[player].hand.remove_at(hand_index)
	trick.append({"player": player, "card": card, "strength": strength})
	played_cards.append({"player": player, "card": card, "strength": strength})
	if trick.size() == order.size():
		var best: Dictionary = trick[0]
		for entry in trick:
			if entry.strength > best.strength:
				best = entry
		last_winner = best.player
		players[last_winner].taken += 1
		completed_tricks += 1
		phase = "trick_complete"
		current = -1
	else:
		current = _next_active(player)
	return true

func advance_trick() -> bool:
	if phase != "trick_complete":
		return false
	if completed_tricks == hand_size:
		_score_round()
	else:
		trick.clear()
		current = last_winner
		phase = "play"
	return true

func _score_round() -> void:
	round_result.clear()
	var least_loss := 100
	for id in order:
		var p: Dictionary = players[id]
		# Freeze the values at the exact moment the round closes. This keeps the
		# life result independent from presentation animations or the next round.
		var declared: int = int(p.bid)
		var taken: int = int(p.taken)
		var loss := absi(declared - taken)
		p["rounds_played"] = int(p.get("rounds_played", 0)) + 1
		p["total_taken"] = int(p.get("total_taken", 0)) + taken
		p["exact_predictions"] = int(p.get("exact_predictions", 0)) + (1 if loss == 0 else 0)
		var previous_lives: int = p.lives
		p.lives = maxi(0, int(p.lives) - loss)
		p.active = p.lives > 0
		least_loss = mini(least_loss, loss)
		round_result.append({"player": id, "bid": declared, "taken": taken, "loss": loss, "lives": p.lives, "previous_lives": previous_lives, "revived": false})
	var survivors := active_ids()
	if survivors.is_empty():
		for result in round_result:
			if result.loss == least_loss:
				survivors.append(result.player)
		if survivors.size() > 1:
			for id in survivors:
				players[id].lives = 1
				players[id].active = true
			for result in round_result:
				if survivors.has(result.player):
					result.lives = 1
					result.revived = true
	if survivors.size() == 1:
		winner = survivors[0]
		phase = "finished"
	else:
		phase = "round_complete"
	current = -1

func view_for(viewer: int) -> Dictionary:
	var visible_players: Array[Dictionary] = []
	for p in players:
		var visible := p.duplicate(true)
		var can_see: bool = p.id == viewer if hand_size > 1 else p.id != viewer
		if not can_see:
			visible.hand = []
			for _card in p.hand:
				visible.hand.append(-1)
		visible_players.append(visible)
	var visible_trick := trick.duplicate(true)
	if hand_size == 1 and phase == "play":
		for entry in visible_trick:
			if entry.player == viewer:
				entry.card = -1
				entry.erase("strength")
	return {"players": visible_players, "phase": phase, "current": current, "hand_size": hand_size,
		"round": round_number, "trick": visible_trick, "legal_bids": legal_bids(viewer), "winner": winner, "seat_order": seat_order.duplicate(),
		"starter": starter, "played_cards": played_cards.duplicate(true) if hand_size > 1 else []}
