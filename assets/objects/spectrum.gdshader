shader_type canvas_item;

uniform vec4 u_spectrumColor : source_color = vec4(0.72549019607, 0.74117647058, 0.74117647058, 1.0);
uniform float u_glow = 1.5;
uniform sampler2D u_white : hint_default_black, filter_nearest;

void fragment() {
	COLOR = mix(COLOR, COLOR * u_spectrumColor * u_glow, texture(u_white, UV).a);
}
