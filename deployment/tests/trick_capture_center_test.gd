extends SceneTree

func _initialize() -> void:
	var controller = load("res://scenes/balatro/scripts/match_controller.gd")
	var card := Control.new()
	card.size = Vector2(115, 174)
	var target := Vector2(470, 280)
	for pivot in [Vector2.ZERO, card.size * 0.5, Vector2(20, 30)]:
		card.pivot_offset = pivot
		for factor in [0.18, 0.70, 1.08]:
			for angle in [-0.18, 0.0, 0.18]:
				card.scale = Vector2.ONE * factor
				card.rotation = angle
				card.position = target - controller._card_center_offset(card, card.scale, angle)
				assert((card.get_transform() * (card.size * 0.5)).is_equal_approx(target))
	card.free()
	print("PASS: capture centers match target for all pivots, scales and rotations")
	quit()
