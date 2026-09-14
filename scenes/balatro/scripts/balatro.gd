extends Control

const Deck = preload("res://scenes/balatro/scripts/deck.gd")
var deck: Deck

func _ready() -> void:
	deck = Deck.new()
	var hand = $Parallax/Hand/HBoxContainer
	hand.deal_from(deck, $Parallax/DeckPile)
