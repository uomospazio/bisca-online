extends RefCounted

# Only accepts Rules.view_for(actor): never the authoritative hands/deck.
const JOKER := 30
const BID_SAMPLES := 64
const PLAY_SAMPLES := 48
var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

func choose_bid(view: Dictionary, actor: int) -> int:
	if view.hand_size == 1:
		return _blind_bid(view, actor)
	var options: Array = view.legal_bids
	var scores := {}
	for bid in options:
		scores[bid] = 0.0
	for sample in range(BID_SAMPLES):
		var world := _sample_world(view, actor)
		for bid in options:
			var players: Array = world.players.duplicate(true)
			players[actor].bid = bid
			_rollout(players, [], int(view.get("starter", actor)), view.seat_order)
			scores[bid] += world.weight * _cost(players, actor)
	var best: int = options[0]
	for bid in options:
		if scores[bid] < scores[best]:
			best = bid
	return best

func choose_play(view: Dictionary, actor: int) -> Dictionary:
	if view.hand_size == 1:
		return {"index": 0, "high": view.players[actor].bid == 1}
	var options := _options(view.players[actor].hand)
	var scores: Array[float] = []
	scores.resize(options.size())
	scores.fill(0.0)
	for sample in range(PLAY_SAMPLES):
		var world := _sample_world(view, actor)
		for index in range(options.size()):
			var players: Array = world.players.duplicate(true)
			_rollout(players, view.trick.duplicate(true), actor, view.seat_order, options[index])
			scores[index] += world.weight * _cost(players, actor)
	var best := 0
	for index in range(1, options.size()):
		if scores[index] < scores[best]:
			best = index
	return options[best]

func _strength(card: int, high: bool = true) -> int:
	return (41 if high else 0) if card == JOKER else card + 1

func _options(hand: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in range(hand.size()):
		result.append({"index": i, "high": true})
		if hand[i] == JOKER:
			result.append({"index": i, "high": false})
	return result

func _potential(hand: Array, count: int) -> float:
	var result := 0.0
	for card in hand:
		result += 1.0 if card == JOKER else pow(float(card + 1) / 41.0, max(1, count - 1))
	return result

func _sample_world(view: Dictionary, actor: int) -> Dictionary:
	var players: Array = view.players.duplicate(true)
	var available: Array[int] = []
	var known := {}
	var count := 0
	for p in players:
		if p.active:
			count += 1
		for card in p.hand:
			if card >= 0:
				known[card] = true
	for entry in view.get("played_cards", []) + view.trick:
		if entry.card >= 0:
			known[entry.card] = true
	for card in range(40):
		if not known.has(card):
			available.append(card)
	for i in range(available.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp: int = available[i]
		available[i] = available[j]
		available[j] = temp
	var log_weight := 0.0
	for p in players:
		for i in range(p.hand.size()):
			if p.hand[i] < 0:
				p.hand[i] = available.pop_back()
		if not p.active:
			continue
		var expected := _potential(p.hand, count)
		if p.id != actor and p.bid >= 0:
			# Soft evidence: a declaration can be optimistic, forced or mistaken.
			var target := maxf(0.0, float(p.bid - p.taken))
			var uncertainty: float = 0.9 + 0.15 * p.hand.size()
			log_weight -= 0.5 * pow((target - expected) / uncertainty, 2.0)
		elif p.bid < 0:
			p.bid = int(round(expected))
	return {"players": players, "weight": exp(maxf(-16.0, log_weight))}

func _cost(players: Array, actor: int) -> float:
	var me: Dictionary = players[actor]
	var loss := absi(int(me.taken - me.bid))
	# Survival matters more than a small secondary opportunity to hurt rivals.
	var result := float(loss) + (1.5 if loss >= me.lives else 0.0)
	if loss == 0:
		for p in players:
			if p.active and p.id != actor:
				result -= 0.005 * mini(absi(int(p.taken - p.bid)), int(p.lives))
	return result

func _rollout(players: Array, trick: Array, current: int, seating: Array, first: Dictionary = {}) -> void:
	var active: Array[int] = []
	for id in seating:
		if players[id].active:
			active.append(id)
	while not players[current].hand.is_empty():
		var move: Dictionary = first if not first.is_empty() else _tactical(players, current, trick, active)
		first = {}
		var card: int = players[current].hand[move.index]
		players[current].hand.remove_at(move.index)
		trick.append({"player": current, "strength": _strength(card, move.high)})
		if trick.size() == active.size():
			var best: Dictionary = trick[0]
			for entry in trick:
				if entry.strength > best.strength:
					best = entry
			current = best.player
			players[current].taken += 1
			trick.clear()
		else:
			current = active[(active.find(current) + 1) % active.size()]

func _tactical(players: Array, actor: int, trick: Array, active: Array) -> Dictionary:
	var me: Dictionary = players[actor]
	var options := _options(me.hand)
	var best: Dictionary = options[0]
	var best_cost := INF
	var leading := -1
	var played := {}
	for entry in trick:
		leading = maxi(leading, int(entry.strength))
		played[entry.player] = true
	var needed := maxi(0, int(me.bid - me.taken))
	for move in options:
		var strength := _strength(me.hand[move.index], move.high)
		var chance := 1.0 if strength > leading else 0.0
		for id in active:
			if id == actor or played.has(id):
				continue
			var other: Dictionary = players[id]
			var below := clampf(float(strength - 1) / 40.0, 0.0, 1.0)
			var wants := clampf(float(other.bid - other.taken) / maxf(1.0, other.hand.size()), 0.0, 1.0)
			var avoids := 1.0 - pow(1.0 - below, other.hand.size())
			var contests := pow(below, maxf(1.0, other.hand.size() * 0.7))
			chance *= lerpf(avoids, contests, wants)
		var left: Array = me.hand.duplicate()
		left.remove_at(move.index)
		var future := _potential(left, active.size())
		var cost := absf(float(needed) - chance - future)
		if needed == 0:
			# Shed dangerous high cards when they can safely lose this trick.
			cost = chance * 4.0 + future * 0.12
		elif needed >= me.hand.size():
			cost = (1.0 - chance) * 4.0 - future * 0.08
		else:
			cost += chance * (1.0 - chance) * 0.15
		if cost < best_cost:
			best_cost = cost
			best = move
	return best

func _blind_bid(view: Dictionary, actor: int) -> int:
	# Enumerate the unknown own card; the player's actual card is never read.
	var visible := {}
	for p in view.players:
		if p.active and p.id != actor:
			for card in p.hand:
				if card >= 0:
					visible[card] = true
	var best_bid: int = view.legal_bids[0]
	var best_cost := INF
	for bid in view.legal_bids:
		var cost := 0.0
		for own_card in range(40):
			if visible.has(own_card):
				continue
			var own_strength := _strength(own_card, bid == 1)
			var win_probability := 1.0
			var weight := 1.0
			for p in view.players:
				if not p.active or p.id == actor or p.hand.is_empty():
					continue
				var card: int = p.hand[0]
				if card == JOKER and p.bid < 0:
					win_probability *= 0.5
				else:
					var other_strength := _strength(card, p.bid != 0)
					if other_strength > own_strength:
						win_probability = 0.0
				# Earlier bidders saw our card: use their claim as weak evidence.
				if p.bid >= 0 and card != JOKER and own_card != JOKER:
					var could_beat := own_strength < card + 1
					weight *= 1.0 if could_beat == (p.bid == 1) else 0.75
			cost += weight * ((1.0 - win_probability) if bid == 1 else win_probability)
		if cost < best_cost:
			best_cost = cost
			best_bid = bid
	return best_bid
