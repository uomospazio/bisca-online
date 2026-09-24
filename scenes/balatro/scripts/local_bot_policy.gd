extends "res://scenes/balatro/scripts/bot_policy.gd"

# Single-player only. Yield between simulated moves (not entire rollouts),
# keeping input/rendering responsive even in thread-free mobile Web exports.
const FRAME_BUDGET_USEC := 1500
const LOCAL_BID_SAMPLES := 8

func decide(view: Dictionary, actor: int, tree: SceneTree, valid: Callable) -> Dictionary:
	if not valid.is_valid() or not valid.call():
		return {}
	var bidding: bool = view.phase == "prediction"
	if view.hand_size == 1:
		return {"bid": choose_bid(view, actor)} if bidding else choose_play(view, actor)
	var options: Array = view.legal_bids if bidding else _options(view.players[actor].hand)
	var scores: Array[float] = []
	scores.resize(options.size())
	scores.fill(0.0)
	var deadline := Time.get_ticks_usec() + FRAME_BUDGET_USEC
	var sample_count := LOCAL_BID_SAMPLES if bidding else PLAY_SAMPLES
	for sample in range(sample_count):
		var world := _sample_world(view, actor)
		for index in range(options.size()):
			var players: Array = world.players.duplicate(true)
			var trick: Array = [] if bidding else view.trick.duplicate(true)
			var current: int = int(view.get("starter", actor)) if bidding else actor
			var first: Dictionary = {} if bidding else options[index]
			if bidding:
				players[actor].bid = options[index]
			var active: Array[int] = []
			for id in view.seat_order:
				if players[id].active:
					active.append(id)
			while not players[current].hand.is_empty():
				if Time.get_ticks_usec() >= deadline or tree.paused:
					await tree.process_frame
					while tree.paused:
						if not valid.is_valid() or not valid.call():
							return {}
						await tree.process_frame
					if not valid.is_valid() or not valid.call():
						return {}
					deadline = Time.get_ticks_usec() + FRAME_BUDGET_USEC
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
			scores[index] += world.weight * _cost(players, actor)
	var best := 0
	for index in range(1, options.size()):
		if scores[index] < scores[best]:
			best = index
	return {"bid": options[best]} if bidding else options[best]
