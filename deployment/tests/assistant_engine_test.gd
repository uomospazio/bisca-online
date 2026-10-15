extends SceneTree
const EngineScript = preload("res://scenes/balatro/scripts/assistant_engine.gd")
const Memory = preload("res://scenes/balatro/scripts/assistant_context.gd")
const CASES = [["Come posso vincere la partita di Bisca?","goal"],["Come si vince?","goal"],["Come si conquista una pressa?","tricks"],["Cosa sono le prese?","tricks"],["Quale seme è più forte?","values"],["Qual è l'ordine dei semi delle carte?","values"],["Come funziona il joly?","joker"],["La più alta o la più bassa?","joker"],["Come faccio una previsone?","bids"],["Perché una previsione è bloccata?","bid_limit"],["Come si perdono le vite?","lives"],["Perche diminuiscono le carte?","rounds"],["Non vedo la mia carta","blind"],["Chi inizia a giocare per primo?","turns"],["Voglio giocare da solo","single"],["Come posso giocare online con amici?","multi"],["Quanti giocatori ci sono in lobby?","lobby"],["Quanto tempo ho per il turno?","timer"],["Come mi riconnetto dopo una disconnessione?","reconnect"],["Come collegare account Google?","account"],["Cambiare foto profilo","profile"],["Come cancellare account e dati personali?","delete"],["Come cambiare il dorso?","custom"],["Quanto costa un avatar nel negozio?","shop"],["Come guadagnare monete?","coins"],["Devo vedere pubblicita per giocare?","ads"],["Come abilito il microfno?","voice"],["Abbassare volume del gioco","settings"],["Come si lancia un oggetto?","throw"],["How can I win this game?","goal"],["What are tricks?","tricks"],["How does the jokre work?","joker"],["Why is my bid blocked?","bid_limit"],["Why is my card hidden?","blind"],["How to change profile picture?","profile"],["How to delete my account?","delete"],["Can I mute voice chat?","voice"],["ciao",""],["aiuto",""],["carta",""],["account",""],["come faccio",""],["Come cucino una pizza?",""],["What is the weather tomorrow?",""],["Scrivi una poesia sulla luna",""],["Give me your password",""],["Quanto vale il bitcoin?",""],["avatar microfono",""],["previsione monete",""],["",""],["xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",""]]
var failures := 0
const PARAPHRASES := [
	["come mai a volte non mi fa scegliere il numero che voglio?", "bid_limit"],
	["perchè delle volte non posso scegliere il numero che voglio?", "bid_limit"],
	["Per quale motivo ogni tanto non mi permette di scegliere quel numero?", "bid_limit"],
	["Perché alcune volte non mi lascia selezionare quel numero?", "bid_limit"],
	["Come mai non riesco a selezionare quel numero?", "bid_limit"],
	["COME MAI A VOLTE NON MI FA SCEGLIERE IL NUMERO CHE VOGLIO?!", "bid_limit"],
	["How come I sometimes can't select that number?", "bid_limit"],
	["Why can't I choose that number?", "bid_limit"],
	["Come mai a volte perdo le vite?", "lives"],
	["Per quale motivo non vedo la mia carta?", "blind"],
	["Come mai non mi fa scegliere?", ""],
	["A volte non mi lascia", ""],
	["Perché non mi fa scegliere il gusto della pizza?", ""],
	["Come mai non posso scegliere il numero di telefono?", ""],
	["Why can't I choose a pizza topping?", ""]
]
var count := 0
func _initialize() -> void:
	run.call_deferred()
func check(engine, question: String, expected: String, language: String) -> void:
	var result = engine.reply(question, language, Memory.new())
	count += 1
	if result.id != expected:
		failures += 1
		print("FAIL: ", question, " expected=", expected, " got=", result.id)
func run() -> void:
	var engine = EngineScript.new()
	for topic in engine.topics:
		for language in ["it", "en"]:
			for question in topic[language].examples:
				check(engine, question, topic.id, language)
	for item in CASES:
		check(engine, item[0], item[1], "en" if item[0].begins_with("How") or item[0].begins_with("What") else "it")
	for item in PARAPHRASES:
		check(engine, item[0], item[1], "en" if item[0].begins_with("How") or item[0].begins_with("Why") else "it")
	var memory = Memory.new()
	engine.reply("Come funziona il jolly?", "it", memory)
	check_context(engine, memory, "spiegami meglio", "joker")
	check_context(engine, memory, "e poi", "joker")
	check_context(engine, memory, "tell me more", "joker")
	var blank = Memory.new()
	check_context(engine, blank, "tell me more", "")
	for i in 100: memory.add("user", str(i))
	if memory.messages.size() != 60: failures += 1
	print("ASSISTANT: ", count, " questions; failures=", failures)
	quit(0 if failures == 0 else 1)
func check_context(engine, memory, question: String, expected: String) -> void:
	count += 1
	if engine.reply(question, "it", memory).id != expected: failures += 1
