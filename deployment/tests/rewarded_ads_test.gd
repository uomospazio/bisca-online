extends SceneTree

class FakeAccount extends Node:
	var user_id := "tester"
	func is_authenticated() -> bool: return true

class Probe extends "res://scenes/balatro/scripts/rewarded_ads.gd":
	var calls := 0
	var reply := {"ok": false, "message": "Rete assente"}
	func _ready() -> void: pass
	func _save() -> void: pass
	func _rpc(_endpoint: String, _payload: Dictionary) -> Dictionary:
		calls += 1
		return reply

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var account := FakeAccount.new()
	root.add_child(account)
	var ads := Probe.new()
	root.add_child(ads)
	ads._account = account
	ads._serial = 7
	ads._record_earned(6, "tester", "solo", "match")
	assert(ads._pending.is_empty(), "Stale native callback must be ignored")
	ads._record_earned(7, "tester", "solo", "match")
	var claim: String = ads._pending.p_claim
	ads._record_earned(7, "tester", "solo", "match")
	assert(ads._pending.p_claim == claim, "Duplicate callbacks must reuse the same claim")
	await ads._claim()
	assert(not ads.busy and ads.pending_for_account(), "Offline claim must remain recoverable")
	account.user_id = "another"
	await ads._claim()
	assert(ads.calls == 1, "Never claim against the wrong account")
	account.user_id = "tester"
	ads.reply = {"ok": true, "credits": 130, "amount": 30}
	await ads._claim()
	assert(ads._pending.is_empty())
	assert(ads.claimed("solo", "match"))
	assert(not ads.claimed("solo", "next-match"))
	assert(not ads.claimed("shop", ""))
	var overlay := preload("res://scenes/balatro/scripts/game_overlay.gd").new()
	root.add_child(overlay)
	overlay.show_victory("Tester", null, {"rounds_played": 5})
	overlay.setup_rewarded_offer("solo", "match")
	await process_frame
	await process_frame
	assert(overlay.rewarded_offer.visible)
	assert(overlay.panel.size.y < 1080, "Reward offer must fit the victory screen")
	assert(overlay.rewarded_offer.button.disabled, "Desktop must not simulate paid ads")
	overlay.announce_turn(true)
	assert(not overlay.rewarded_offer.visible, "Hide ad offer outside the final result")
	overlay.queue_free()
	ads.queue_free()
	account.queue_free()
	await process_frame
	print("PASS: stale/duplicate reward callbacks, offline retry, account switch, one reward per match, victory layout, desktop disabled")
	quit()
