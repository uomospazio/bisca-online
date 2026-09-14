extends Node

var peers: Dictionary = {}
var network_session: Node
var data_channels: Dictionary = {}
var last_states: Dictionary = {}

func _ready() -> void:
	network_session = get_node_or_null("/root/NetworkSession")

	if network_session == null:
		push_error("NetworkSession non trovato")
		return

	network_session.updated.connect(_on_network_updated)

	print("VoiceChat pronto")


func _on_network_updated(state: Dictionary) -> void:
	if not state.has("you"):
		return

	var my_slot: int = int(state.you)
	var people: Array = state.get("people", [])

	for slot in range(people.size()):
		if slot == my_slot:
			continue

		var person: Dictionary = people[slot]

		if person.get("bot", false):
			continue

		if not person.get("connected", false):
			continue

		if peers.has(slot):
			continue

		_create_peer(slot, my_slot)


func _create_peer(target_slot: int, my_slot: int) -> void:
	var peer := WebRTCPeerConnection.new()

	var err := peer.initialize({
		"iceServers": [
			{
				"urls": [
					"stun:stun.l.google.com:19302"
				]
			}
		]
	})

	if err != OK:
		push_error("Errore inizializzazione WebRTC")
		return

	peers[target_slot] = peer

	var channel := peer.create_data_channel(
		"voice",
		{
			"negotiated": true,
			"id": 1,
			"ordered": false
		}
	)

	if channel == null:
		push_error("Impossibile creare data channel per slot %d" % target_slot)
		peers.erase(target_slot)
		return

	data_channels[target_slot] = channel

	peer.session_description_created.connect(
		func(type: String, sdp: String):
			_on_session_description_created(
				target_slot,
				type,
				sdp
			)
	)

	peer.ice_candidate_created.connect(
		func(media: String, index: int, candidate: String):
			_on_ice_candidate_created(
				target_slot,
				media,
				index,
				candidate
			)
	)

	print("Creato peer WebRTC verso slot ", target_slot)

	if my_slot < target_slot:
		peer.create_offer()

func _on_session_description_created(
	target_slot: int,
	type: String,
	sdp: String
) -> void:

	var peer: WebRTCPeerConnection = peers[target_slot]

	peer.set_local_description(type, sdp)

	network_session.voice_signal.rpc_id(
		1,
		target_slot,
		{
			"type": "description",
			"description_type": type,
			"sdp": sdp
		}
	)


func _on_ice_candidate_created(
	target_slot: int,
	media: String,
	index: int,
	candidate: String
) -> void:

	network_session.voice_signal.rpc_id(
		1,
		target_slot,
		{
			"type": "candidate",
			"media": media,
			"index": index,
			"candidate": candidate
		}
	)


func _process(_delta: float) -> void:
	for slot in peers:
		var peer: WebRTCPeerConnection = peers[slot]

		peer.poll()

		var state := peer.get_connection_state()

		if not last_states.has(slot) or last_states[slot] != state:
			last_states[slot] = state

			match state:
				WebRTCPeerConnection.STATE_NEW:
					print("Voice ", slot, ": NEW")

				WebRTCPeerConnection.STATE_CONNECTING:
					print("Voice ", slot, ": CONNECTING")

				WebRTCPeerConnection.STATE_CONNECTED:
					print("✅ Voice ", slot, ": CONNECTED")

				WebRTCPeerConnection.STATE_DISCONNECTED:
					print("⚠️ Voice ", slot, ": DISCONNECTED")

				WebRTCPeerConnection.STATE_FAILED:
					print("❌ Voice ", slot, ": FAILED")

				WebRTCPeerConnection.STATE_CLOSED:
					print("Voice ", slot, ": CLOSED")
