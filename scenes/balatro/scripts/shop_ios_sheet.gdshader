shader_type canvas_item;

uniform float sheet_top;
varying vec2 sheet_pixel;

void vertex() {
    sheet_pixel = VERTEX;
}

void fragment() {
    if (sheet_pixel.x < 300.0 && sheet_pixel.y + sheet_top > 535.0) {
        discard;
    }
}
