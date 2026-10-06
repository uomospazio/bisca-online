extends RefCounted

const AvatarData = preload("res://scenes/balatro/scripts/avatar_data.gd")
const TEXTURES := [
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 1.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 2.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 3.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 4.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 5.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 6.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 7.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 8.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 9.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 10.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 11.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 12.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 13.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 14.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 15.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 16.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 17.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 18.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 19.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 20.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 21.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 22.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 23.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 24.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 25.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 26.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 27.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 28.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 29.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 30.png"),
	preload("res://scenes/balatro/trick_asset/avatar/Avatar 31.png"),
	preload("res://scenes/balatro/trick_asset/avatar/AvatarSpecial.png"),
]
static var cache: Dictionary = {}

static func encoded(index: int) -> String:
	index = posmod(index, TEXTURES.size())
	if cache.has(index):
		return cache[index]
	var image: Image = TEXTURES[index].get_image()
	if image.is_compressed():
		image.decompress()
	var side := mini(image.get_width(), image.get_height())
	image = image.get_region(Rect2i((image.get_width() - side) / 2, (image.get_height() - side) / 2, side, side))
	image.resize(192, 192, Image.INTERPOLATE_LANCZOS)
	image.convert(Image.FORMAT_RGB8)
	for quality in [0.8, 0.65, 0.5, 0.35, 0.2]:
		var value := Marshalls.raw_to_base64(image.save_jpg_to_buffer(quality))
		if value.length() <= AvatarData.MAX_ENCODED:
			cache[index] = value
			return value
	return ""
