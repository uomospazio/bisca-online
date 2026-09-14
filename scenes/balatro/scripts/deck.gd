extends RefCounted

const CardData = preload("res://scenes/balatro/scripts/card_data.gd")
const ASSET_FOLDER := "res://scenes/balatro/trick_asset/mazzo_2/briscola/"
const ASSET_RANKS := ["Ace", "2", "3", "4", "5", "6", "7", "Jack", "Queen", "King"]

var cards: Array[CardData] = []

func _init() -> void:
	for colour in range(4):
		for number in range(1, 11):
			var card := CardData.new()
			card.colour = colour
			card.number = number
			var filename := "Suit=%s, Rank=%s, Front _=Yes.png" % [CardData.COLOUR_NAMES[colour].capitalize(), ASSET_RANKS[number - 1]]
			card.texture = load(ASSET_FOLDER + filename) as Texture2D
			cards.append(card)
	shuffle()

func shuffle() -> void:
	cards.shuffle()

func draw(count: int) -> Array[CardData]:
	var drawn: Array[CardData] = []
	for index in range(mini(maxi(count, 0), cards.size())):
		drawn.append(cards.pop_back())
	return drawn

func remaining_count() -> int:
	return cards.size()
