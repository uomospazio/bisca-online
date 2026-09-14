extends SceneTree

const Rules = preload("res://scenes/balatro/scripts/match_rules.gd")
const SyncBot = preload("res://scenes/balatro/scripts/bot_policy.gd")
const LocalBot = preload("res://scenes/balatro/scripts/local_bot_policy.gd")
var ticks := 0

func _initialize() -> void:
	process_frame.connect(func(): ticks += 1)
	_run.call_deferred()

func _run() -> void:
	for count in [2, 8]:
		for size in [5, 3, 1]:
			var rules = Rules.new()
			rules.start(count, 831)
			while rules.hand_size != size:
				rules.phase = "round_complete"
				rules.begin_round()
			var actor: int = rules.current
			var sync = SyncBot.new()
			var local = LocalBot.new()
			var view: Dictionary = rules.view_for(actor)
			var before := view.duplicate(true)
			sync.rng.seed = 4321
			local.rng.seed = 4321
			var started := Time.get_ticks_usec()
			var bid: int = sync.choose_bid(view, actor)
			var sync_ms := (Time.get_ticks_usec() - started) / 1000.0
			var first_tick := ticks
			var decision: Dictionary = await local.decide(view, actor, self, func(): return true)
			assert(decision.bid == bid, "Bid changed")
			assert(view == before, "View mutated")
			print("BID players=%d cards=%d synchronous=%.1fms yielded_frames=%d" % [count, size, sync_ms, ticks - first_tick])
			if size == 5 and count == 8:
				assert(ticks - first_tick > 1, "Bot did not yield")
			while rules.phase == "prediction":
				rules.predict(rules.current, rules.legal_bids(rules.current)[0])
			actor = rules.current
			# Include both joker options in the ordinary play test.
			if size > 1:
				rules.players[actor].hand[0] = 30
			view = rules.view_for(actor)
			sync.rng.seed = 9876
			local.rng.seed = 9876
			var play: Dictionary = sync.choose_play(view, actor)
			decision = await local.decide(view, actor, self, func(): return true)
			assert(decision == play, "Play changed")
	var rules = Rules.new()
	rules.start(8, 67)
	var local = LocalBot.new()
	var state := {"valid": true}
	process_frame.connect(func(): state.valid = false, CONNECT_ONE_SHOT)
	var result: Dictionary = await local.decide(rules.view_for(rules.current), rules.current, self, func(): return state.valid)
	assert(result.is_empty(), "Cancelled bot returned a move")
	paused = true
	create_timer(0.06, true).timeout.connect(func(): paused = false)
	var start := Time.get_ticks_msec()
	result = await local.decide(rules.view_for(rules.current), rules.current, self, func(): return true)
	assert(Time.get_ticks_msec() - start >= 60, "Ignored pause")
	assert(not result.is_empty())
	print("PASS: equivalent decisions, responsive frames, unchanged views, cancellation and pause")
	quit()
