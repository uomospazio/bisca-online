extends RefCounted
## Deliberately bounded retrieval, not a generative model.
const DATA := "res://scenes/balatro/data/assistant_knowledge.json"
const MAX_INPUT := 300
const STOP := "a al alla alle ai agli all anche che chi come con da dal dalle dei del della delle di e ed è gli i il in la le lo l ma mi mia mio ne nel nella non o per posso quale quali qual quanto quante quanti quando se si sono su sul the a an and are am is it of to do does can how what which why when my your i in on with me about for please"
const ALIASES := {"jolly": "joker", "previsioni": "previsione", "dichiarare": "dichiarazione", "prese": "presa", "carte": "carta", "dorsi": "dorso", "avatars": "avatar", "predictions": "prediction", "tricks": "trick", "cards": "card", "bids": "bid"}
const SYNONYMS := {"vince": "vincere", "vinco": "vincere", "vittoria": "vincere", "joly": "joker", "perdo": "perdere", "perdono": "perdere", "perdi": "perdere", "gioco": "giocare", "play": "playing", "collego": "collegare", "collega": "collegare", "cambio": "cambiare", "change": "changing", "costa": "prezzo", "costano": "prezzo", "cost": "price", "riconnetto": "riconnessione", "riconnettere": "riconnessione", "accendo": "abilitare", "abilito": "abilitare", "attivo": "abilitare", "spengo": "disattivare", "disattivo": "disattivare"}
const FILLER := ["cosa", "funziona", "funzionano", "fare", "faccio", "devo", "voglio", "possono", "ci", "una", "uno", "un", "ho", "ha", "miei", "mie", "mio", "dopo", "possiamo", "bisca", "this", "work", "works", "game"]
const DISTINCT := ["vincere", "joker", "presa", "microfono", "timer", "riconnessione", "pubblicita"]
# Apply whole phrases before removing stop words, equally to queries and examples.
# These map language, not topics: "non mi fa" alone never means a forbidden bid.
const PHRASES := [
	["semi", "seme"], ["forti", "forte"], ["abbassare", "abbasso"],
	["piu forte", "forza"],
	["come mai", "perche"], ["per quale motivo", "perche"],
	["non mi permette di", "non posso"], ["non mi lascia", "non posso"],
	["non mi fa", "non posso"], ["non riesco a", "non posso"],
	["non e possibile", "non posso"],
	["delle volte", ""], ["alcune volte", ""], ["certe volte", ""], ["a volte", ""], ["ogni tanto", ""],
	["selezionare", "scegliere"], ["seleziono", "scegliere"],
	["how come", "why"], ["for what reason", "why"],
	["does not let me", "cannot"], ["doesn t let me", "cannot"],
	["won t let me", "cannot"], ["can t", "cannot"],
	["from time to time", ""], ["sometimes", ""],
	["choose", "select"]
]
var topics: Array = []
var index: Array[Dictionary] = []

func _init() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	if not data is Dictionary or not data.get("topics") is Array:
		return
	topics = data.topics
	for topic in topics:
		for language in ["it", "en"]:
			var entry: Dictionary = topic[language]
			var examples: Array = []
			for example in entry.examples:
				examples.append(tokens(example))
			index.append({"id": topic.id, "language": language, "keywords": tokens(" ".join(entry.keywords)), "examples": examples})

static func normalize(value: String) -> String:
	value = value.to_lower().strip_edges()
	for pair in [["à", "a"], ["è", "e"], ["é", "e"], ["ì", "i"], ["ò", "o"], ["ù", "u"], ["’", " "]]:
		value = value.replace(pair[0], pair[1])
	value = RegEx.create_from_string("[^a-z0-9 ]").sub(value, " ", true)
	return " ".join(value.split(" ", false))

static func tokens(value: String) -> Array[String]:
	var result: Array[String] = []
	var canonical := " " + normalize(value) + " "
	for pair in PHRASES:
		canonical = canonical.replace(" " + pair[0] + " ", " " + pair[1] + " ")
	for word in canonical.split(" ", false):
		if word in STOP.split(" "): continue
		# Question framing must not count as evidence of a game mechanic.
		if word in ["perche", "quel", "quello", "quella", "that", "cannot"]: continue
		word = ALIASES.get(word, word)
		word = SYNONYMS.get(word, word)
		if word in FILLER: continue
		if not word in result: result.append(word)
	return result

static func close_word(left: String, right: String) -> bool:
	if left == right: return true
	# A single edit/transposition on longer words, never on short words/numbers.
	if mini(left.length(), right.length()) < 5 or absi(left.length() - right.length()) > 1: return false
	if left.length() == right.length():
		var mismatches: Array[int] = []
		for i in left.length():
			if left[i] != right[i]: mismatches.append(i)
		if mismatches.size() == 1: return true
		return mismatches.size() == 2 and mismatches[1] == mismatches[0] + 1 and left[mismatches[0]] == right[mismatches[1]] and left[mismatches[1]] == right[mismatches[0]]
	var short_word := left if left.length() < right.length() else right
	var long_word := right if left.length() < right.length() else left
	for i in long_word.length():
		if long_word.erase(i, 1) == short_word: return true
	return false

static func overlap(query: Array[String], vocabulary: Array[String]) -> int:
	var count := 0
	for word in query:
		for candidate in vocabulary:
			if close_word(word, candidate):
				count += 1
				break
	return count

func topic_by_id(id: String) -> Dictionary:
	for topic in topics:
		if topic.id == id: return topic
	return {}

func answer_topic(id: String, language: String, context: RefCounted) -> Dictionary:
	var topic := topic_by_id(id)
	if topic.is_empty(): return fallback(language)
	context.last_topic = id
	return {"id": id, "text": topic[language].answer, "suggestions": topic.related, "recognized": true}

func fallback(language: String, suggestions: Array = ["goal", "bids", "account"]) -> Dictionary:
	return {"id": "", "text": "Non sono sicuro di aver capito. Posso aiutarti con le regole e le funzioni di Bisca. Puoi precisare, oppure scegliere un argomento qui sotto?" if language == "it" else "I'm not sure I understood. I can help with Bisca rules and features. Could you clarify, or choose a topic below?", "suggestions": suggestions, "recognized": false}

func reply(value: String, language: String, context: RefCounted) -> Dictionary:
	language = "en" if language == "en" else "it"
	if value.strip_edges().is_empty() or value.length() > MAX_INPUT: return fallback(language)
	var normalized := normalize(value)
	if normalized in ["e poi", "spiegami meglio", "puoi spiegare meglio", "in che senso", "dimmi di piu", "tell me more", "explain more", "what do you mean"]:
		if not context.last_topic.is_empty():
			var result := answer_topic(context.last_topic, language, context)
			result.text += "\n\n" + ("Quale aspetto vuoi approfondire? Scegli una domanda correlata." if language == "it" else "Which part would you like to explore? Choose a related question.")
			return result
	var query := tokens(value)
	if query.is_empty(): return fallback(language)
	var scores := {}
	for entry in index:
		var matched := overlap(query, entry.keywords)
		var score := 0.0
		if matched >= 2:
			score = float(matched) / query.size() * 0.85
		elif query.size() == 1 and matched == 1 and query[0] in DISTINCT:
			score = 0.75
		for example in entry.examples:
			var hits := overlap(query, example)
			if hits == 0: continue
			var precision := float(hits) / query.size()
			var recall := float(hits) / maxi(1, example.size())
			if precision >= 0.75 and (hits >= 2 or (query.size() == 1 and example.size() == 1)):
				score = maxf(score, 2.0 * precision * recall / (precision + recall))
		scores[entry.id] = maxf(float(scores.get(entry.id, 0.0)), score)
	var ranked := scores.keys()
	ranked.sort_custom(func(a, b): return scores[a] > scores[b])
	if ranked.is_empty() or scores[ranked[0]] < 0.64: return fallback(language)
	if ranked.size() > 1 and scores[ranked[0]] - scores[ranked[1]] < 0.09:
		return fallback(language, [ranked[0], ranked[1]])
	return answer_topic(ranked[0], language, context)
