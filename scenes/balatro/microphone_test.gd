extends AudioStreamPlayer

@onready var playback_player: AudioStreamPlayer = $"../VoicePlayback"

var capture: AudioEffectCapture
var playback: AudioStreamGeneratorPlayback

const FRAME_SIZE := 960


func _ready() -> void:
	var bus_index := AudioServer.get_bus_index("VoiceCapture")

	if bus_index == -1:
		push_error("Bus VoiceCapture non trovato")
		return

	capture = AudioServer.get_bus_effect(bus_index, 0) as AudioEffectCapture

	if capture == null:
		push_error("AudioEffectCapture non trovato")
		return

	if playback_player == null:
		push_error("VoicePlayback non assegnato")
		return

	playback_player.play()

	playback = playback_player.get_stream_playback() as AudioStreamGeneratorPlayback

	if playback == null:
		push_error("AudioStreamGeneratorPlayback non disponibile")
		return

	print("Loopback microfono pronto")


func _process(_delta: float) -> void:
	if capture == null or playback == null:
		return

	while capture.get_frames_available() >= FRAME_SIZE:
		var frames: PackedVector2Array = capture.get_buffer(FRAME_SIZE)

		for frame in frames:
			if playback.can_push_buffer(1):
				playback.push_frame(frame)
