extends SceneTree

class Host extends Control:
	var online := false
	var overlay := Control.new()
	var home_visits := 0
	func _show_menu() -> void: home_visits += 1

class Flow extends "res://scenes/balatro/scripts/match_result_flow.gd":
	var flights: Array = []
	func _fly(amount: int, balance: int, center: bool) -> void:
		flights.append({"amount":amount,"balance":balance,"center":center})
	func _mark_base_done() -> void:
		handled[_key()] = true # Never write the real user's preferences in a test.

func _initialize() -> void:
	run.call_deferred()

func shot(flow: Node, name: String) -> void:
	flow.art.render()
	await process_frame
	if "--visual" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/private/tmp/bisca-result-"+name+".png")

func run() -> void:
	create_timer(25).timeout.connect(func(): quit(1))
	root.size = Vector2i(1920,884)
	var host := Host.new()
	root.add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var table := TextureRect.new()
	host.add_child(table)
	table.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	table.texture = load("res://scenes/balatro/trick_asset/table.png")
	table.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	table.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	host.add_child(host.overlay)
	var flow := Flow.new()
	host.add_child(flow)
	flow.setup(host)
	flow.handled.clear()
	flow.account_id = str(root.get_node("AccountSession").user_id)
	flow.match_id = "test-match"
	flow.receipt = {"amount":30,"season_points":50,"credits":130}
	flow._open()
	assert(flow.coins()==30 and flow.points()==50 and flow.placement()=="multi")
	await shot(flow,"elimination")
	await flow.skip()
	assert(not flow.active and flow.base_done() and flow.flights[0].amount==30)
	assert(host.home_visits==0,"Elimination returns to spectators, not home")
	flow.final_screen = true
	var avatar := load("res://scenes/balatro/trick_asset/avatar/Avatar 1.png")
	flow.podium = [{"name":"PRIMO","avatar":avatar},{"name":"SECONDO","avatar":avatar},{"name":"TERZO","avatar":avatar}]
	flow._open()
	assert(flow.placement()=="multi_final")
	assert(not flow.art.coin.is_visible_in_tree(),"Do not show base rewards twice")
	await shot(flow,"spectator-podium")
	flow.watching = true
	assert(flow.accepts_ad(flow.account_id,"multi_final",flow.match_id))
	assert(not flow.accepts_ad("wrong-account","multi_final",flow.match_id))
	root.get_node("NetworkSession").latest = {"stage":"lobby"}
	await flow.present_ad_reward({"amount":50,"credits":180})
	assert(flow.flights.back().amount==50 and flow.flights.back().center)
	flow.match_id = "test-winner"
	flow.receipt = {"amount":50,"season_points":200,"credits":230}
	flow._open()
	await shot(flow,"podium")
	assert(flow.art.coin.is_visible_in_tree() and flow.points()==200)
	await flow.present_ad_reward({"amount":50,"credits":280})
	assert(flow.flights.back().amount==100 and not flow.flights.back().center)
	flow.match_id = "test-solo-skip"
	flow.solo = true
	flow.won = true
	flow._open()
	await shot(flow,"solo-win")
	var before: int = flow.flights.size()
	await flow.skip()
	assert(flow.flights.size()==before and host.home_visits==1,"Solo skip awards nothing")
	flow.match_id = "test-solo-redeem"
	flow._open()
	await flow.present_ad_reward({"amount":30,"season_points":50,"credits":310})
	assert(flow.flights.back().amount==30 and host.home_visits==2)
	flow.match_id = "test-final-during-ad"
	flow.solo = false
	flow.final_screen = false
	flow.final_pending = true
	flow._open()
	await flow.skip()
	assert(flow.active and flow.final_screen and flow.base_done())
	assert(flow.placement()=="multi_final")
	print("PASS: elimination/spectator, independent final podium, optional +50 ads, solo redeem/skip, no duplicate base reward, owner guard")
	quit()
