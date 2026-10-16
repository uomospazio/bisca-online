extends CanvasLayer
## Presentation only: every multiplayer amount comes from a server receipt.
const SAVE := "user://bisca_result_choices.cfg"
var host: Control
var art: Control
var active := false
var busy := false
var watching := false
var solo := false
var won := false
var final_screen := false
var final_pending := false
var match_id := ""
var account_id := ""
var receipt: Dictionary = {}
var receipts: Dictionary = {}
var handled: Dictionary = {}
var finished: Dictionary = {}
var podium: Array = []
var error_message := ""
var sounded: Dictionary = {}

func setup(controller: Control) -> void:
	host = controller
	layer = 125
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("match_result_flow")
	var config := ConfigFile.new()
	if config.load(SAVE)==OK:
		handled = config.get_value("results","handled",{})
	art = preload("res://scenes/balatro/scripts/match_result_art.gd").new()
	add_child(art)
	art.setup_result(self)
	get_node("/root/RewardedAds").changed.connect(_ads_changed)
	get_node("/root/AccountSession").changed.connect(func():
		if active and str(get_node("/root/AccountSession").user_id)!=account_id:
			active = false
			watching = false
			hide())
	hide()

func _key() -> String:
	return account_id+":"+match_id

func base_done() -> bool:
	return handled.has(_key())

func coins() -> int:
	return 30 if solo else int(receipt.get("amount",0))

func points() -> int:
	return 50 if solo else int(receipt.get("season_points",0))

func placement() -> String:
	return "solo" if solo else ("multi_final" if final_screen and base_done() else "multi")

func receive_receipt(value: Dictionary) -> void:
	var uid := str(get_node("/root/AccountSession").user_id)
	if str(value.get("user_id",""))!=uid: return
	var id := str(value.get("match_id",""))
	receipts[uid+":"+id] = value.duplicate(true)
	if active and account_id==uid and match_id==id:
		receipt = value.duplicate(true)
		if not busy: art.render()
	var balance_sync := preload("res://scenes/balatro/scripts/match_reward_popup.gd").new()
	add_child(balance_sync)
	await balance_sync._refresh_balance(uid)
	if is_instance_valid(balance_sync): balance_sync.queue_free()

func _process(_delta: float) -> void:
	if active or not is_instance_valid(host) or not host.online or host.online_match.processing: return
	if host.menu.visible or host.rules.players.is_empty() or host.rules.players[0].active: return
	if host.rules.phase=="finished": return # Podium is opened by _show_victory.
	var uid := str(get_node("/root/AccountSession").user_id)
	var id := str(host.online_match.state.get("reward_match",""))
	var key := uid+":"+id
	if handled.has(key) or not receipts.has(key): return
	account_id = uid
	match_id = id
	receipt = receipts[key].duplicate(true)
	solo = bool(host.online_match.state.get("singleplayer",false))
	won = false
	final_screen = false
	final_pending = false
	_open()

func show_final() -> void:
	var id: String = str(host.online_match.state.get("reward_match","")) if host.online else host.solo_ad_match
	var uid := str(get_node("/root/AccountSession").user_id)
	if finished.has(uid+":"+id): return
	_capture_podium()
	if active and match_id==id:
		if not final_screen: final_pending = true
		return
	match_id = id
	account_id = uid
	solo = not host.online or bool(host.online_match.state.get("singleplayer",false))
	won = host.rules.winner==0
	final_screen = true
	final_pending = false
	receipt = receipts.get(_key(),{}).duplicate(true)
	if not solo and not bool(host.online_match.state.get("reward_expected",true)) and receipt.is_empty():
		receipt = {"amount":0,"season_points":0,"credits":int(get_node("/root/AccountProfile").profile.get("credits",0))}
	_open()

func show_solo_elimination() -> void:
	match_id = host.solo_ad_match
	account_id = str(get_node("/root/AccountSession").user_id)
	solo = true
	won = false
	final_screen = true
	final_pending = false
	receipt = {}
	_open()

func _open() -> void:
	active = true
	busy = false
	watching = false
	error_message = ""
	host.overlay.hide()
	if final_screen and (not solo or won) and not sounded.has(_key()):
		sounded[_key()] = true
		var audio := preload("res://scenes/balatro/scripts/game_audio.gd")
		audio.play(self,audio.VICTORY)
	art.render()
	show()

func _capture_podium() -> void:
	podium.clear()
	var order: Array = []
	var places: Dictionary = host.online_match.state.get("season_places",{})
	var count: int = host.rules.players.size()
	for i in count:
		var server_id: int = (i+host.online_match.local_id)%count if host.online else i
		var rank: int = int(places.get(server_id,places.get(str(server_id),8)))
		if i==host.rules.winner: rank=1
		order.append({"id":i,"rank":rank,"server":server_id})
	order.sort_custom(func(a,b): return a.rank<b.rank if a.rank!=b.rank else a.server<b.server)
	for entry in order.slice(0,3):
		var index: int = entry.id
		var texture: Texture2D = host.scores.get_child(index).profile_texture if index<host.scores.get_child_count() else null
		podium.append({"name":host._name_of(index),"avatar":texture})

func watch_ad() -> void:
	var ads := get_node("/root/RewardedAds")
	if busy or ads.busy: return
	if ads.pending_for_account() and (str(ads._pending.p_context)!=match_id or str(ads._pending.p_placement)!=placement()):
		error_message = "Recupera prima il premio in sospeso dal pulsante originale."
		art.refresh()
		return
	busy = true
	watching = true
	error_message = ""
	art.refresh()
	ads.request_reward(placement(),match_id)

func accepts_ad(uid: String, ad_placement: String, context: String) -> bool:
	return active and watching and uid==account_id and context==match_id and ad_placement==placement()

func _ads_changed() -> void:
	if not active: return
	var ads := get_node("/root/RewardedAds")
	if watching and not ads.busy:
		watching = false
		busy = false
		error_message = ads.message
	art.refresh()

func present_ad_reward(result: Dictionary) -> void:
	watching = false
	var base := 0 if solo or base_done() else coins()
	var total := base+int(result.get("amount",0))
	art.amount.text = "+%d" % total
	if solo: art.xp.text = "+%d" % int(result.get("season_points",0))
	await get_tree().create_timer(0.35).timeout
	if not _same_account(): return
	await _fly(total,int(result.get("credits",0)),not solo and base_done())
	if not _same_account(): return
	_mark_base_done()
	_complete()

func skip() -> void:
	if busy: return
	busy = true
	art.refresh()
	if not solo and not base_done():
		var balance := int(receipt.get("credits",get_node("/root/AccountProfile").profile.get("credits",0)))
		await _fly(coins(),balance,false)
		if not _same_account(): return
		_mark_base_done()
	_complete()

func _fly(amount: int, balance: int, from_center: bool) -> void:
	if amount<=0: return
	var helper := preload("res://scenes/balatro/scripts/match_reward_popup.gd").new()
	add_child(helper)
	var source: TextureRect = art.coin
	var label: Label = art.amount
	if from_center:
		# No base reward row on the spectator's final screen.
		source = TextureRect.new()
		source.texture = preload("res://scenes/balatro/trick_asset/ui_bisca/coin.png")
		source.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		source.size = Vector2(110,110)
		art.add_child(source)
		source.position = art.get_viewport_rect().size/2-source.size/2
		label = Label.new()
		art.add_child(label)
	await helper._animate_coins_to_balance(art,source,label,{"amount":amount,"credits":balance})
	if from_center:
		source.queue_free()
		label.queue_free()
	helper.queue_free()

func _same_account() -> bool:
	return active and str(get_node("/root/AccountSession").user_id)==account_id

func _mark_base_done() -> void:
	handled[_key()] = true
	var config := ConfigFile.new()
	config.set_value("results","handled",handled)
	config.save(SAVE)
	if not solo:
		var net := get_node("/root/NetworkSession")
		if host.online: net.reward_seen.rpc_id(1,match_id)

func _complete() -> void:
	var go_home := solo
	var go_lobby := final_screen and not solo
	busy = false
	active = false
	hide()
	if final_pending and not go_home:
		final_pending = false
		final_screen = true
		_open()
		return
	if go_home:
		finished[_key()] = true
		host._show_menu()
	elif go_lobby:
		finished[_key()] = true
		var net := get_node("/root/NetworkSession")
		if net.latest.get("stage","")!="lobby":
			host.online_match.action({"op":"return_lobby"})
