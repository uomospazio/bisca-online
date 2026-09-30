extends SceneTree

class RewardProbe extends "res://scenes/balatro/scripts/match_reward_popup.gd":
	func _refresh_balance(_uid: String) -> void:
		balance_loading = false # Nessuna richiesta HTTP nel test.

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var menu = load("res://scenes/balatro/scripts/main_menu.gd").new()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	menu.home_persistent_ui.get_node("CoinsCounter").modulate.a = 0.0
	var popup := RewardProbe.new()
	root.add_child(popup)
	popup.show_reward({"user_id": "", "amount": 30, "outcome": "elimination", "credits": 130})
	await create_timer(0.4).timeout
	assert(popup.get_child_count() == 1)
	var reward := popup.find_child("RewardAmount", true, false) as Control
	assert((reward.get_global_transform_with_canvas() * (reward.size / 2.0)).is_equal_approx(root.get_visible_rect().size / 2.0), "Premio al centro dello schermo")
	assert(popup.find_children("*", "Button", true, false).is_empty(), "La ricompensa non deve avere CONTINUA")
	await create_timer(1.1).timeout
	var counter := popup.find_child("CoinsCounter", true, false)
	assert(counter != null and counter.visible)
	assert(counter.modulate.a == 1.0, "Il contatore deve comparire anche se la HOME è nascosta")
	var screen_position: Vector2 = counter.get_global_transform_with_canvas().origin
	var expected := Vector2(root.get_visible_rect().size.x - 40 - 320, 32)
	print("Reward counter: ", screen_position, " expected: ", expected)
	assert(screen_position.is_equal_approx(expected), "Contatore fuori posizione rispetto ai bordi dello schermo")
	for screen_size in [Vector2i(2340, 1080), Vector2i(1440, 1080), Vector2i(1920, 1080)]:
		root.size = screen_size
		await process_frame
		await process_frame
		expected = Vector2(root.get_visible_rect().size.x - 360, 32)
		assert(counter.get_global_transform_with_canvas().origin.is_equal_approx(expected), "Margini stabili dopo resize")
	var label := counter.find_child("CoinsAmount", true, false)
	assert(label.text == "100", "Prima del volo mostrare il saldo precedente")
	await create_timer(1.9).timeout
	assert(label.text == "130", "Dopo il volo mostrare saldo + premio")
	var destination: Vector2 = counter.get_global_transform_with_canvas() * (counter.size / 2.0)
	for child in popup.get_child(0).get_children():
		if child is TextureRect:
			assert((child.get_global_transform_with_canvas() * (child.size / 2.0)).is_equal_approx(destination), "Le monete devono arrivare nel contatore")
	await create_timer(1.8).timeout
	assert(not is_instance_valid(popup), "Il banner deve chiudersi automaticamente")
	var host = load("res://scenes/balatro/balatro.tscn").instantiate()
	root.add_child(host)
	current_scene = host
	host.set_process(false)
	host.menu.hide()
	host.online = true
	host.rules.players.clear()
	host.rules.players.append({"active": false})
	host.rules.phase = "round_complete"
	host.online_match.processing = true
	host.online_match.state = {"stage": "damage"}
	var gate := RewardProbe.new()
	root.add_child(gate)
	var progress := {"done": false}
	wait_gate(gate, progress)
	await create_timer(0.1).timeout
	assert(not progress.done, "Attendere la perdita vite")
	host.online_match.processing = false
	host.online_match.state.stage = "turn"
	await create_timer(0.1).timeout
	assert(progress.done, "Dopo le vite mostrare il premio dell'eliminato")
	host.rules.phase = "finished"
	progress.done = false
	wait_gate(gate, progress)
	await create_timer(0.2).timeout
	assert(not progress.done, "Prima leggere il banner vincitore")
	await create_timer(2.1).timeout
	assert(progress.done)
	gate.queue_free()
	print("PASS: reward without continue, coin counter, automatic completion")
	quit()

func wait_gate(popup: RewardProbe, progress: Dictionary) -> void:
	await popup._wait_for_match_presentation()
	progress.done = true
