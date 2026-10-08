extends RefCounted

# Put the files in scenes/balatro/resources and enter their filenames here.
# Empty strings keep the corresponding slots disabled. Re-export and deploy
# both client and server after changing this list.
const FILES := [
	"poop.png", 
	"gay.png", 
	"fazzoletti.png",
	"cry.png",
	"sorry.png",
	"clown.png",
	"angry.png",
	"pollo.png",
	"",
]

static func enabled(index: int) -> bool:
	return index >= 0 and index < FILES.size() and not FILES[index].is_empty()

# Add a matching audio file (e.g. poop.png -> audio/poop.mp3), then re-export.
# ResourceLoader also resolves imported audio inside mobile/Web export packages.
static func impact_sound(index: int) -> AudioStream:
	if enabled(index):
		var basename: String = FILES[index].get_file().get_basename()
		for extension in ["mp3", "ogg", "wav"]:
			var path: String = "res://scenes/balatro/audio/" + basename + "." + extension
			if ResourceLoader.exists(path, "AudioStream"):
				var sound := load(path) as AudioStream
				if sound != null:
					return sound
	return preload("res://scenes/balatro/audio/impact.mp3")
