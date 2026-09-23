extends RefCounted

# Put the files in scenes/balatro/resources and enter their filenames here.
# Empty strings keep the corresponding slots disabled. Re-export and deploy
# both client and server after changing this list.
const FILES := [
	"poop.svg", # Slot 1: upper right
	"fword.svg", # Slot 2: right — e.g. "tomato.svg"
	"", # Slot 3: lower right — e.g. "egg.svg"
]

static func enabled(index: int) -> bool:
	return index >= 0 and index < FILES.size() and not FILES[index].is_empty()
