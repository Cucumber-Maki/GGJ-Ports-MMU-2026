shader_type canvas_item;

uniform vec4 u_gridColor1 : source_color;
uniform vec4 u_gridColor2 : source_color;
uniform sampler2D u_baseGridTexture : filter_nearest;

uniform float u_gridSize = 8;
uniform vec3 u_activeColor = vec3(1.0, 0.0, 0.0);

varying vec2 v_worldPos;

const ivec2 tileset_size = ivec2(28, 11);


void vertex() {
	v_worldPos = (vec4(VERTEX, 1.0, 1.0)).xy / u_gridSize;
}

vec2 tile_uv(vec2 uv, vec2 uvOffset) {
	return (floor(uv * vec2(tileset_size)) + uvOffset) / vec2(tileset_size);
}
bool is_active(sampler2D tex, vec2 uv) {
	const vec2 offsets[] = { vec2(0.95), vec2(0.5, 0.96), vec2(0.05), vec2(0.0, 0.95) };
	
	for (int i = 0; i < offsets.length(); i++) {
		vec2 specialuv = tile_uv(uv, offsets[i]);
		vec4 color = texture(tex, specialuv);
		if (length(color.rgb - vec3(1, 0.451, 0.541)) < 0.01) color.rgb = vec3(1.0, 0.0, 0.0);
		if (length(color.rgb - vec3(0.451, 1, 0.541)) < 0.01) color.rgb = vec3(0.0, 1.0, 0.0);
		if (length(color.rgb - vec3(0.451, 0.541, 1)) < 0.01) color.rgb = vec3(0.0, 0.0, 1.0);
		
		if (color.rgb == vec3(1.0, 0.0, 0.0) || 
			color.rgb == vec3(0.0, 1.0, 0.0) || 
			color.rgb == vec3(0.0, 0.0, 1.0)) {
			return color.rgb == u_activeColor;
		}
	}
	return true;
}

void fragment() {
	if (COLOR.rgb == vec3(1.0, 1.0, 0.0)) {
		COLOR.rgb = mix(u_gridColor1, u_gridColor2, mod(floor(v_worldPos.x) + floor(v_worldPos.y), 2.0)).rgb;
	} else if (COLOR.rgb == vec3(1.0, 0.0, 0.0) || COLOR.rgb == vec3(0.0, 1.0, 0.0) || COLOR.rgb == vec3(0.0, 0.0, 1.0)) {
		COLOR.rgb *= mix(u_gridColor1, u_gridColor2, mod(floor(v_worldPos.x) + floor(v_worldPos.y), 2.0)).rgb;
	}
	
	if (!is_active(TEXTURE, UV)) {
		vec4 baseColor = texture(u_baseGridTexture, UV);
		baseColor.rgb = mix(u_gridColor1, u_gridColor2, mod(floor(v_worldPos.x) + floor(v_worldPos.y), 2.0)).rgb;
		COLOR = mix(COLOR * 0.5, baseColor, 0.4);
	}
}
