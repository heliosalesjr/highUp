shader_type canvas_item;

uniform float metal_intensity : hint_range(0.0, 1.0) = 1.0;
uniform vec3 metal_tint : source_color = vec3(0.7, 0.8, 0.9); // Azul metálico
uniform float shine_speed : hint_range(0.0, 5.0) = 2.0;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	if (tex_color.a > 0.1) { // Só afeta pixels visíveis
		// Converte para grayscale
		float gray = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
		
		// Adiciona tint metálico
		vec3 metal_color = vec3(gray) * metal_tint;
		
		// Brilho animado que percorre
		float shine = sin(UV.x * 10.0 + TIME * shine_speed) * 0.3 + 0.7;
		metal_color *= shine;
		
		// Interpola entre cor original e metal
		vec3 final_color = mix(tex_color.rgb, metal_color, metal_intensity);
		
		COLOR = vec4(final_color, tex_color.a);
	} else {
		COLOR = tex_color;
	}
}