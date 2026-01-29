shader_type canvas_item;

uniform sampler2D backgroundtextures[4]:repeat_enable,filter_nearest;
uniform vec2 offsetposition;

void fragment() {
	COLOR.a = 0.0;
	
	vec2 uv=UV;
	vec2 layermultiplier=offsetposition;
	layermultiplier.y = 0.0;
	
	for(int i=0;i<backgroundtextures.length();i++){
		if (i < 2) {
			vec2 baseUv = uv + layermultiplier + vec2(0.0, min(offsetposition.y, 0));
			baseUv.y = clamp(baseUv.y, 0.0, 1.0);
			COLOR = mix(texture(backgroundtextures[i], baseUv), COLOR, COLOR.a);
			if (offsetposition.y > 0.0)
				COLOR.a = max(1.0 - offsetposition.y, 0.0) * COLOR.a;
		} else {
			COLOR = mix(texture(backgroundtextures[i], uv + layermultiplier), COLOR, COLOR.a);
		}
		layermultiplier/=1.3;
		if(COLOR.a>=1.0){
			break;
		}
	}
}
