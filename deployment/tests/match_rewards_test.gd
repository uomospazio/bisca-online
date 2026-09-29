extends SceneTree

class Rewards extends "res://scenes/balatro/scripts/match_rewards_server.gd":
	func enabled() -> bool:
		return true
	func _flush() -> void:
		pass

class RewardPanel extends "res://scenes/balatro/scripts/match_reward_popup.gd":
	func _refresh_balance(_uid: String) -> void:
		pass

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var rewards := Rewards.new()
	var rules = load("res://scenes/balatro/scripts/match_rules.gd").new()
	rules.start(3)
	var room := {"options": {"starting_cards": 5}, "rules": rules, "people": [
		{"bot": false, "peer": 2, "account_id": "a"},
		{"bot": false, "peer": 3, "account_id": "b"},
		{"bot": false, "peer": 4, "account_id": "c"}]}
	rewards.start_match(room)
	assert(room.reward_eligible)
	assert(str(room.reward_match).length() == 36)
	rewards.observe(room)
	assert(rewards.pending.is_empty())
	rules.players[0].active = false
	rewards.observe(room)
	assert(rewards.pending.size() == 1)
	assert(rewards.pending.values()[0].p_outcome == "elimination")
	rewards.observe(room)
	assert(rewards.pending.size() == 1)
	# Il bot che sostituisce un disconnesso non invalida la partita gia' iniziata.
	room.people[1].peer = 0
	rules.players[1].active = false
	rules.phase = "finished"
	rules.winner = 2
	rewards.observe(room)
	assert(rewards.pending.size() == 3)
	assert(rewards.pending[room.reward_match + ":c"].p_outcome == "victory")
	room.options.starting_cards = 4
	rewards.start_match(room)
	assert(not room.reward_eligible)
	rewards.pending.clear()
	rewards.observe(room)
	assert(not rewards.pending.is_empty()) # statistiche anche senza premio
	assert(not rewards.pending.values()[0].p_reward)
	room.options.starting_cards = 5
	rewards.start_match(room)
	assert(room.reward_eligible) # temporaneamente ammessi anche due umani
	room.people[1].peer = 3
	room.people[1].account_id = "a"
	rewards.start_match(room)
	assert(room.reward_eligible) # account duplicato non blocca la partita
	rewards.pending.clear()
	rewards.observe(room)
	assert(rewards.pending.size() == 2) # sempre un solo premio per account
	room.people[1] = {"bot": true, "peer": 0, "account_id": ""}
	room.people[2] = {"bot": true, "peer": 0, "account_id": ""}
	rewards.start_match(room)
	assert(room.reward_eligible)
	assert(room.reward_users.size() == 1)
	rewards.pending.clear()
	rewards.observe(room)
	assert(rewards.pending.size() == 1) # eliminazione umano, nessun premio ai bot
	assert(rewards.pending.values()[0].p_outcome == "elimination")
	rewards.start_match(room)
	rewards.pending.clear()
	rules.winner = 0
	rewards.observe(room)
	assert(rewards.pending.size() == 1)
	assert(rewards.pending.values()[0].p_outcome == "victory")
	rewards.free()
	var popup := RewardPanel.new()
	root.add_child(popup)
	popup.show_reward({"user_id": "test", "outcome": "victory", "amount": 50})
	await create_timer(1.3).timeout
	assert(popup.get_child_count() == 1)
	var panel: Control = popup.get_child(0).get_child(0)
	assert(panel.scale.is_equal_approx(Vector2.ONE))
	assert(panel.get_child(2).text == "+50")
	popup.queue_free()
	print("PASS: eligibility, elimination, victory, idempotency, duplicate accounts, popup animation")
	quit()
