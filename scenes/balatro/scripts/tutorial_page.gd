extends "res://scenes/balatro/scripts/multiplayer_entry_ui.gd"
signal finished(completed: bool)

const Rules = preload("res://scenes/balatro/scripts/match_rules.gd")
const TutorialSkin = preload("res://scenes/balatro/scripts/generic_ui_skin.gd")
const SIZE := Vector2(1800, 900)
const PORTRAITS := [
	"res://scenes/balatro/trick_asset/ui_bisca/pngUI/tutorialUI/Immagine ChatGPT 10 ott 2026, 13_42_28-1.png",
	"res://scenes/balatro/trick_asset/ui_bisca/pngUI/tutorialUI/Immagine ChatGPT 10 ott 2026, 13_42_29-2.png",
	"res://scenes/balatro/trick_asset/ui_bisca/pngUI/tutorialUI/Immagine ChatGPT 10 ott 2026, 13_42_30-3.png",
	"res://scenes/balatro/trick_asset/ui_bisca/pngUI/tutorialUI/Immagine ChatGPT 10 ott 2026, 13_42_31-4.png"]
enum Step { GOAL, TAKE, VALUES, STRATEGY, BID, TARGET, LIVES, ROUNDS, BLIND, LOOP }
var target_action := 0
var rules = Rules.new()
var step := Step.GOAL
var portrait: TextureRect
var board: Control
var dialogue: Control
var text_label: Label
var next_button: Button
var heading: Label
var hint: Label
var actions: Control
var hand_buttons: Array[Button] = []
var action_buttons: Array[Button] = []
var progress: Label
var pulse: Tween
var portrait_pop: Tween
var table_background: TextureRect

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	font = preload("res://scenes/balatro/fonts/Comic Lemon.otf").duplicate() as FontFile
	font.multichannel_signed_distance_field = true
	# Same full-screen, aspect-cover table as the real match. The guide is
	# an overlay, never a sidebar that changes the play area's dimensions.
	table_background = _image(self, "res://scenes/balatro/trick_asset/table.png", Rect2())
	table_background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	table_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	composition = Control.new()
	add_child(composition)
	composition.size = SIZE
	_action(composition, "SALTA TUTORIAL", Rect2(1430, 0, 340, 70), func(): finished.emit(false))
	board = Control.new()
	composition.add_child(board)
	hint = _label(composition, "", Rect2(660, 570, 1080, 55), 27, Color("ffda7c"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait = _image(composition, PORTRAITS[0], Rect2(-75, 420, 560, 840))
	portrait.pivot_offset = Vector2(280, 560)
	dialogue = Panel.new()
	composition.add_child(dialogue)
	dialogue.position = Vector2(25, 120)
	dialogue.size = Vector2(1120, 340)
	TutorialSkin.apply(dialogue, false)
	heading = _label(dialogue, "", Rect2(32, 18, 1056, 48), 34, Color("b7a4e8"))
	text_label = _label(dialogue, "", Rect2(32, 76, 1056, 170), 32)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progress = _label(dialogue, "", Rect2(32, 268, 430, 48), 24, Color("b7a4e8"))
	next_button = _action(dialogue, "AVANTI", Rect2(870, 263, 210, 60), advance)
	actions = Control.new()
	composition.add_child(actions)
	_prepare_round(false)
	get_viewport().size_changed.connect(_fit)
	_fit()
	_render()

func _layout(bounds: Rect2) -> void:
	var factor := minf(bounds.size.x / SIZE.x, bounds.size.y / SIZE.y)
	composition.scale = Vector2.ONE * maxf(0.01, factor)
	composition.position = bounds.get_center() - SIZE * composition.scale / 2

func _action(parent: Node, caption: String, rect: Rect2, callback: Callable) -> Button:
	var button := Button.new()
	parent.add_child(button)
	button.text = caption
	button.position = rect.position
	button.size = rect.size
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 26)
	TutorialSkin.apply(button, true)
	button.pressed.connect(callback)
	RoundedSquareButton.ButtonAudio.attach(button)
	return button

func _prepare_round(blind: bool) -> void:
	rules.configure({"lives": 3, "starting_cards": 1 if blind else 2})
	rules.start(3, 42)
	rules.starter = 0
	rules.current = 0
	rules.order.assign([0, 1, 2])
	var hands := [[35], [29], [39]] if blind else [[30, 0], [19, 21], [9, 29]]
	for i in 3: rules.players[i].hand = hands[i].duplicate()

func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func _card(parent: Node, id: int, at: Vector2, enabled := false) -> Button:
	var button := Button.new()
	parent.add_child(button)
	button.position = at
	button.size = Vector2(108, 158)
	button.disabled = not enabled
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var picture := TextureRect.new()
	picture.texture = get_node("/root/GameSettings").back_texture() if id < 0 else get_node("/root/GameSettings").front_texture(id / 10, id % 10 + 1)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = MOUSE_FILTER_IGNORE
	button.add_child(picture)
	picture.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	return button

func _render_board() -> void:
	_clear_children(board)
	hand_buttons.clear()
	# La prima schermata presenta solo l'obiettivo, prima della distribuzione.
	if step == Step.GOAL: return
	if step < Step.BID:
		if step == Step.TAKE:
			for i in 3: _card(board, [0, 19, 29][i], Vector2(850 + i * 155, 145))
		return
	var view: Dictionary = rules.view_for(0)
	for i in 3:
		var p: Dictionary = rules.players[i]
		var at := Vector2(820, 702) if i == 0 else Vector2(745 if i == 1 else 1400, 165)
		var caption := "%s · %d VITE\nPRESE %d / %s" % ["TU" if i == 0 else "BOT " + str(i), p.lives, p.taken, "?" if p.bid < 0 else str(p.bid)]
		var badge_at := Vector2(1065, 750) if i == 0 else at + Vector2(-60, -62)
		var badge := _label(board, caption, Rect2(badge_at, Vector2(285 if i == 0 else 370, 60)), 24)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var cards: Array = view.players[i].hand
		for c in cards.size():
			var enabled := i == 0 and step == Step.TARGET and target_action in [0, 2] and c == 0
			var button := _card(board, cards[c], at + Vector2(c * 124, 0), enabled)
			if i == 0:
				hand_buttons.append(button)
				button.pressed.connect(_play_own.bind(c))
				if enabled: _highlight(button)
	for i in rules.trick.size():
		_card(board, rules.trick[i].card, Vector2(1020 + 125 * i, 165))

func _highlight(control: Control) -> void:
	control.pivot_offset = control.size / 2
	pulse = create_tween().set_loops()
	pulse.tween_property(control, "scale", Vector2.ONE * 1.07, 0.45)
	pulse.tween_property(control, "scale", Vector2.ONE, 0.45)

func _render() -> void:
	if pulse and pulse.is_valid(): pulse.kill()
	dialogue.position = Vector2(510, 530) if step == Step.VALUES else Vector2(510, 350)
	_clear_children(actions)
	action_buttons.clear()
	_render_board()
	progress.text = "IMPARA A GIOCARE · %d / 10" % (step + 1)
	next_button.visible = step not in [Step.BID, Step.BLIND] and not (step == Step.TARGET and target_action < 3)
	next_button.text = "GIOCHIAMO!" if step == Step.LOOP else "AVANTI"
	hint.text = ""
	var words: Array = [
		["L'OBIETTIVO", "BISCA è un battle royale di carte.\nSe perdi tutte le vite, sei fuori.\nRimani l’ultimo in gioco per vincere!", 0],
		["COS'È UNA PRESA", "In ogni giro, tutti giocano una carta.\nLa carta dal valore maggiore conquista la presa.", 1],
		["IL VALORE DELLE CARTE", "Denari > Coppe > Spade > Bastoni: ritrovi questo ordine nei simboli al centro del tavolo!\nNello stesso seme: Re > Cavallo > Fante > 7 > 6 > 5 > 4 > 3 > 2 > Asso.", 1],
		["PRENDERE NON È SEMPRE GIUSTO", "Vincere più prese degli altri non è l'obiettivo.\nA volte conviene lasciare la presa a un avversario.\nIl motivo? Prima di giocare fai una previsione!", 2],
		["IL GIRO DELLE PREVISIONI", "A turno, ognuno dichiara quante prese pensa di fare.\nL'ultimo non può far coincidere il totale con le prese disponibili. Per questa prova, scegli 1.", 2],
		["RISPETTA LA PREVISIONE", "Hai dichiarato 1: prova a fare esattamente una presa.\nL'Asso di Denari è il jolly: ALTO batte tutto, BASSO perde contro tutto. Tocca il jolly evidenziato.", 1],
		["SE SBAGLI, PERDI VITE", "Tu: 1 prevista, 1 fatta = nessuna vita persa.\nBot 1: 1 prevista, 0 fatte = perde 1 vita.\nOgni presa in più o in meno costa una vita!", 1],
		["I ROUND A SCENDERE", "Il numero di carte scende a ogni round:\n5, poi 4, 3, 2 e infine 1.\nOgni round ricomincia con nuove previsioni.", 1],
		["IL ROUND A UNA CARTA", "Vedi le carte degli altri, ma non la tua! Prevedi 0 o 1: la carta si gioca da sola. Il jolly è ALTO con 1, BASSO con 0. Qui un bot ha il Re di Denari: scegli 0.", 2],
		["SI RIPARTE!", "Dopo il round a una carta si torna al numero iniziale e il ciclo ricomincia.\nContinua a rispettare le previsioni e proteggi le vite: vince l'ultimo rimasto!", 3]]
	heading.text = words[step][0]
	text_label.text = words[step][1]
	portrait.texture = load(PORTRAITS[words[step][2]])
	if portrait_pop and portrait_pop.is_valid(): portrait_pop.kill()
	portrait.scale = Vector2.ONE * 0.85
	portrait.modulate.a = 0.0
	portrait_pop = create_tween().set_parallel(true)
	portrait_pop.tween_property(portrait, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	portrait_pop.tween_property(portrait, "modulate:a", 1.0, 0.15)
	if step in [Step.BID, Step.BLIND]:
		var correct := 1 if step == Step.BID else 0
		for bid in (3 if step == Step.BID else 2):
			var button := _action(actions, str(bid) + (" PRESA" if bid == 1 else " PRESE"), Rect2(1020 + bid * 195, 613, 180, 60), _bid.bind(bid))
			action_buttons.append(button)
			if bid == correct: _highlight(button)
	elif step == Step.TARGET:
		if target_action == 1:
			text_label.text = "Gioca il jolly ALTO per conquistare la presa che hai previsto.\nSe scegliessi BASSO, sarebbe la carta più debole."
			var high := _action(actions, "ALTO", Rect2(1380, 613, 210, 60), _joker_high)
			action_buttons.append(high)
			_highlight(high)
		elif target_action == 2:
			text_label.text = "Presa tua! Hai raggiunto la previsione: 1 su 1.\nOra gioca l'Asso di Bastoni rimasto: lascia vincere un bot per non fare prese in più."
		elif target_action == 3:
			text_label.text = "Perfetto: una presa prevista, una presa fatta!\nHai rispettato la tua previsione. Vediamo cosa succede a chi non ci è riuscito."

func advance() -> void:
	if step == Step.LOOP:
		finished.emit(true)
		return
	if step in [Step.BID, Step.BLIND] or (step == Step.TARGET and target_action < 3): return
	if step == Step.ROUNDS: _prepare_round(true)
	step += 1
	_render()

func _bid(value: int) -> void:
	if step not in [Step.BID, Step.BLIND]: return
	var expected := 1 if step == Step.BID else 0
	if value != expected:
		heading.text = "IN QUESTA PROVA SCEGLI %d" % expected
		return
	if not rules.predict(0, value): return
	rules.predict(1, 1)
	rules.predict(2, 1)
	if step == Step.BLIND:
		for player in 3: rules.play(player, 0)
		rules.advance_trick()
		step = Step.LOOP
	else:
		step = Step.TARGET
	_render()

func _play_own(index: int) -> void:
	if step != Step.TARGET or index != 0: return
	if target_action == 0:
		target_action = 1
		_render()
	elif target_action == 2:
		rules.advance_trick()
		rules.play(0, 0)
		rules.play(1, 0)
		rules.play(2, 0)
		rules.advance_trick()
		target_action = 3
		_render()

func _joker_high() -> void:
	if step != Step.TARGET or target_action != 1: return
	rules.play(0, 0, true)
	rules.play(1, 0)
	rules.play(2, 0)
	target_action = 2
	_render()
