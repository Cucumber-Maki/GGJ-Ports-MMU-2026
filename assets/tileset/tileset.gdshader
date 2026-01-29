shader_type canvas_item;

uniform vec4 u_gridColor1 : source_color;
uniform vec4 u_gridColor2 : source_color;
uniform float u_gridSize = 8;

varying vec2 v_worldPos;

void vertex() {
	v_worldPos = (MODEL_MATRIX * vec4(VERTEX, 1.0, 1.0)).xy / u_gridSize;
}

void fragment() {
	if (COLOR.rgb == vec3(1.0, 1.0, 0.0)) {
		COLOR.rgb = mix(u_gridColor1, u_gridColor2, mod(floor(v_worldPos.x) + floor(v_worldPos.y), 2.0)).rgb;
	} else if (COLOR.rgb == vec3(1.0, 0.0, 0.0) || COLOR.rgb == vec3(0.0, 1.0, 0.0) || COLOR.rgb == vec3(0.0, 0.0, 1.0)) {
		COLOR.rgb *= mix(u_gridColor1, u_gridColor2, mod(floor(v_worldPos.x) + floor(v_worldPos.y), 2.0)).rgb;
	}
}
