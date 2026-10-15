extends RefCounted
## Session memory only. No account IDs, files or network access.
const LIMIT := 60
var last_topic := ""
var messages: Array[Dictionary] = []

func add(role: String, text: String) -> void:
	messages.append({"role": role, "text": text})
	while messages.size() > LIMIT:
		messages.pop_front()
