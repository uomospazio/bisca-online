extends SceneTree

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var safety := root.get_node("PlayerSafety")
	var net := root.get_node("NetworkSession")
	safety.account_id = "self"
	safety.loaded = true
	net.latest = {"you":0,"people":[{"account_id":"self","name":"A","bot":false},
		{"account_id":"other","name":"B","bot":false},{"name":"Bot","bot":true}]}
	safety.open_slot(0)
	safety.open_slot(2)
	assert(safety.sheet == null)
	safety.open_slot(1)
	assert(safety.sheet.visible)
	var buttons: Array = safety.sheet.find_children("*","Button",true,false)
	var report: Button
	var block: Button
	for btn in buttons:
		if btn.text in ["Segnala giocatore","Report player"]: report = btn
		if btn.text in ["Blocca giocatore","Block player"]: block = btn
	assert(report != null and block != null)
	report.pressed.emit()
	var reasons: OptionButton = safety.sheet.find_children("*","OptionButton",true,false)[0]
	assert(reasons.item_count == 3)
	safety.open_slot(1)
	safety._confirm_block("other","B")
	assert(safety.sheet.visible)
	safety.blocked["other"] = true
	assert(not safety.allow_voice("other") and safety.allow_voice("different"))
	safety._close()
	await process_frame
	print("PASS: self/bot exclusion, player sheet, report reasons, block confirmation and voice filter")
	quit()
