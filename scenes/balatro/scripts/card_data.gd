extends Resource

enum Colour { BASTONI, SPADE, COPPE, DENARI }

const COLOUR_NAMES := ["bastoni", "spade", "coppe", "denari"]
const RANK_NAMES := ["Asso", "2", "3", "4", "5", "6", "7", "Fante", "Cavallo", "Re"]

@export var colour: Colour = Colour.BASTONI
@export_range(1, 10) var number: int = 1
@export var texture: Texture2D

var strength: int:
	get:
		return int(colour) * 10 + number

var id: String:
	get:
		return "%s_%d" % [COLOUR_NAMES[colour], number]

var display_name: String:
	get:
		return "%s di %s" % [RANK_NAMES[number - 1], COLOUR_NAMES[colour]]
