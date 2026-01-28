shader_type canvas_item;

uniform sampler2D backgroundtextures[4]:repeat_enable,filter_nearest;
uniform vec2 offsetposition;

void fragment() {
	vec2 uv=UV;
	vec2 layermultiplier=offsetposition;
	for(int i=0;i<backgroundtextures.length();i++){
		COLOR=texture(backgroundtextures[i],uv+layermultiplier);
		layermultiplier/=1.3;
		if(COLOR.a>0.0){
			break;
		}
	}
}
