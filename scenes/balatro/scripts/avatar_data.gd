extends RefCounted

const MAX_ENCODED := 32768
const MAX_SIDE := 256

# Check JPEG dimensions before decoding untrusted network data.
static func decode(encoded: String) -> Image:
	if encoded.is_empty() or encoded.length() > MAX_ENCODED:
		return null
	if encoded.length() % 4 != 0 or RegEx.create_from_string("^[A-Za-z0-9+/]+={0,2}$").search(encoded) == null:
		return null
	var bytes := Marshalls.base64_to_raw(encoded)
	if bytes.size() < 4 or bytes[0] != 255 or bytes[1] != 216:
		return null
	var offset := 2
	var dimensions_ok := false
	while offset + 3 < bytes.size():
		if bytes[offset] != 255:
			return null
		while offset < bytes.size() and bytes[offset] == 255:
			offset += 1
		if offset + 2 >= bytes.size():
			return null
		var marker := bytes[offset]
		offset += 1
		if marker == 218 or marker == 217:
			break
		var length := (int(bytes[offset]) << 8) | int(bytes[offset + 1])
		if length < 2 or offset + length > bytes.size():
			return null
		if marker in [192, 193, 194]:
			if length < 8:
				return null
			var height := (int(bytes[offset + 3]) << 8) | int(bytes[offset + 4])
			var width := (int(bytes[offset + 5]) << 8) | int(bytes[offset + 6])
			if width < 1 or width > MAX_SIDE or height != width:
				return null
			dimensions_ok = true
		offset += length
	if not dimensions_ok:
		return null
	var result := Image.new()
	if result.load_jpg_from_buffer(bytes) != OK:
		return null
	return result

static func circular_texture(encoded: String) -> Texture2D:
	var image := decode(encoded)
	if image == null:
		return null
	image.convert(Image.FORMAT_RGBA8)
	var radius := image.get_width() / 2.0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			color.a = clampf(radius - Vector2(x + 0.5 - radius, y + 0.5 - radius).length(), 0.0, 1.0)
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)
