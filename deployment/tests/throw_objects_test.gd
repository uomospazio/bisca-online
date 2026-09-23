extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var host = load("res://scenes/balatro/balatro.tscn").instantiate()
	root.add_child(host)
	var throws: Control
	for child in host.game_ui.get_children():
		if child.get_script() == load("res://scenes/balatro/scripts/throw_objects.gd"):
			throws = child
	assert(throws != null)
	assert(throws.poop != null and throws.menu_button.icon != null)
	for i in range(2):
		var badge = load("res://scenes/balatro/scripts/player_badge.gd").new()
		host.scores.add_child(badge)
		badge.position = Vector2(100 + i * 400, 200)
	host.game_ui.show()
	throws._open(true)
	await create_timer(0.35).timeout
	assert(throws.item.visible and throws.item.scale.is_equal_approx(Vector2.ONE))
	var children: int = throws.get_child_count()
	throws._launch(0, 1)
	assert(throws.get_child_count() == children + 1)
	await create_timer(1.9).timeout
	assert(throws.get_child_count() == children)
	throws.remaining = 8
	throws._process(0.1)
	assert(throws.menu_button.disabled)
	throws.remaining = 0
	throws._process(0)
	assert(not throws.menu_button.disabled)
	host.online = true
	host.online_match.local_id = 1
	throws._received(0, 1)
	assert(throws.get_child_count() == children + 1)
	var projectile = throws.get_child(children)
	var origin: Vector2 = throws._point(host.scores.get_child(1), Vector2(80, 128)) - projectile.size / 2
	assert(projectile.position.is_equal_approx(origin))
	throws._received(1, 0)
	assert(throws.get_child_count() == children + 1)
	await create_timer(0.72).timeout
	var destination: Vector2 = throws._point(host.scores.get_child(0), Vector2(80, 128)) - projectile.size / 2
	assert(projectile.position.is_equal_approx(destination))
	print("PASS: recipient sees sender-to-self trajectory; no duplicate sender echo")
	print("PASS: throw icons, picker tween, projectile cleanup, cooldown")
	quit()
