extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var page := Control.new()
	root.add_child(page)
	var pop := preload("res://scenes/balatro/scripts/page_pop.gd").new()
	var calls := [0]
	var fit := func(): calls[0] += 1
	pop.play(page,fit)
	assert(pop.amount==0.0)
	await create_timer(0.3).timeout
	assert(pop.amount>0.0 and calls[0]>1)
	pop.play(page,fit) # Rapid reopening must replace the previous tween.
	await create_timer(0.65).timeout
	assert(is_equal_approx(pop.amount,1.0))
	page.queue_free()
	await process_frame
	print("PASS: entrance pop, layout updates and rapid reopening")
	quit()
