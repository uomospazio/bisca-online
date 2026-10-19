extends Translation

const MESSAGES = preload("res://scenes/balatro/scripts/ui_english.gd").MESSAGES
var lookup: Dictionary = {}
var formats: Array = []
var placeholder_regex := RegEx.create_from_string("%[-+0-9.]*[sdif]")
var bbcode_regex := RegEx.create_from_string("\\[[^\\]]*\\]|[^\\[]+")
var ordinal_regex := RegEx.create_from_string("^([0-9]+)°$")

func _init() -> void:
	for source in MESSAGES:
		lookup[source] = MESSAGES[source]
		lookup[source.to_upper()] = MESSAGES[source].to_upper()
	for source in lookup:
		if "%" not in source: continue
		var parts := placeholder_regex.search_all(source)
		if parts.is_empty(): continue
		var pattern := "^"
		var offset := 0
		for part in parts:
			pattern += _escape(source.substr(offset, part.get_start() - offset))
			pattern += "(.*?)" if part.get_string() == "%s" else "([0-9.,-]+)"
			offset = part.get_end()
		pattern += _escape(source.substr(offset)) + "$"
		formats.append([RegEx.create_from_string(pattern), str(lookup[source]), source])

func _escape(value: String) -> String:
	for character in ["\\", ".", "^", "$", "*", "+", "?", "(", ")", "[", "]", "{", "}", "|"]:
		value = value.replace(character, "\\" + character)
	return value

func _get_message(source: StringName, _context: StringName) -> StringName:
	if locale == "it": return source
	var value := str(source)
	if lookup.has(value): return lookup[value]
	for entry in formats:
		var found: RegExMatch = entry[0].search(value)
		if found:
			var result: String = entry[1]
			for index in range(1, found.get_group_count() + 1):
				var placeholder := placeholder_regex.search(result)
				if placeholder:
					var replacement := found.get_string(index)
					# Only catalog items/options are nested translations, never names.
					if str(entry[2]).to_lower().begins_with("vuoi acquistare") or str(entry[2]).to_lower() in ["diminuisci %s", "aumenta %s"]:
						var nested := str(_get_message(replacement, &""))
						if not nested.is_empty(): replacement = nested
					result = result.substr(0, placeholder.get_start()) + replacement + result.substr(placeholder.get_end())
			return result
	# RichTextLabel passes BBCode with its text. Translate text runs, not tags.
	if "[" in value:
		var result := ""
		for part in bbcode_regex.search_all(value):
			var fragment := part.get_string()
			var translated := "" if fragment.begins_with("[") else str(_get_message(fragment, &""))
			result += fragment if translated.is_empty() else translated
		return result if result != value else &""
	# Composed status messages and paragraphs retain all whitespace/layout.
	for separator in ["\n", " · ", "     "]:
		if separator in value:
			var parts := value.split(separator)
			for index in parts.size():
				var translated := str(_get_message(parts[index], &""))
				if not translated.is_empty(): parts[index] = translated
			var joined: String = separator.join(parts)
			if joined != value: return joined
	var stripped := value.strip_edges()
	if not stripped.is_empty() and stripped != value:
		var translated := str(_get_message(stripped, &""))
		if not translated.is_empty(): return value.replace(stripped, translated)
	for prefix in ["CLASSIFICA "]:
		if value.begins_with(prefix):
			var rest := value.trim_prefix(prefix)
			var translated := str(_get_message(rest, &""))
			return str(lookup[prefix]) + (rest if translated.is_empty() else translated)
	var ordinal := ordinal_regex.search(value)
	if ordinal:
		var number := int(ordinal.get_string(1))
		var suffix := "th"
		if number % 100 not in [11, 12, 13]: suffix = {1:"st", 2:"nd", 3:"rd"}.get(number % 10, "th")
		return str(number) + suffix
	return &""
