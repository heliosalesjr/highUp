// player_glow.gdshader
shader_type canvas_item;

uniform vec3 core_color : source_color = vec3(0.1, 0.2, 0.3); // Cor do centro (escuro)
uniform vec3 border_color : source_color = vec3(0.2, 0.8, 1.0); // Cor da borda (brilhante)
uniform float border_thickness : hint_range(0.0, 0.5) = 0.15;
uniform float glow_intensity : hint_range(0.0, 10.0) = 4.0;
uniform float pulse_speed : hint_range(0.0, 10.0) = 3.0;
uniform float wave_speed : hint_range(0.0, 5.0) = 2.0;

void fragment() {
	vec2 uv = UV - 0.5; // Centraliza
	
	// Distância do centro (para bordas)
	float dist_from_center = max(abs(uv.x), abs(uv.y)) * 2.0;
	
	// Pulso temporal
	float pulse = sin(TIME * pulse_speed) * 0.3 + 0.7;
	
	// Onda que percorre as bordas
	float wave = sin(uv.x * 10.0 + TIME * wave_speed) * 0.5 + 0.5;
	float wave2 = sin(uv.y * 10.0 - TIME * wave_speed * 0.7) * 0.5 + 0.5;
	float combined_wave = (wave + wave2) * 0.5;
	
	// Define se está na borda ou no centro
	float border_mask = smoothstep(1.0 - border_thickness - 0.1, 1.0 - border_thickness + 0.1, dist_from_center);
	
	// Cor base
	vec3 base_color = mix(core_color, border_color, border_mask);
	
	// Adiciona glow extra nas bordas
	float glow = border_mask * glow_intensity * pulse * combined_wave;
	vec3 final_color = base_color + border_color * glow;
	
	// Alpha baseado na forma quadrada
	float alpha = 1.0 - smoothstep(0.95, 1.0, dist_from_center);
	
	COLOR = vec4(final_color, alpha);
}