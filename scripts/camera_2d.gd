# camera_2d.gd
extends Camera2D

@export var target: Node2D  # O player
@export var smoothing_enabled = true
@export var smoothing_speed = 5.0

const ROOM_HEIGHT = 320

var fixed_x_position = 360  # Meio da tela (720 / 2)
var highest_y_reached = 1280  # Começa no bottom

# Shake variables
var shake_strength = 0.0
var shake_decay = 5.0
var shake_timer = 0.0

# Referência para a Main (para gerar novas salas)
var main_scene: Node2D

func _ready():
	# Fixa a posição X no centro da tela
	position.x = fixed_x_position
	
	# Configura a câmera
	zoom = Vector2(1, 1)
	position_smoothing_enabled = smoothing_enabled
	position_smoothing_speed = smoothing_speed
	
	# Pega referência da Main
	main_scene = get_parent()
	
	# Posição inicial da câmera
	global_position.y = 640  # Centro vertical da tela (1280 / 2)

func _process(delta):
	if not target:
		return
	
	# Aplica shake se ativo
	apply_shake(delta)
	
	# Segue o player apenas no eixo Y
	var target_y = target.global_position.y
	
	# Só move a câmera se o player subir acima do centro da tela
	var camera_target_y = target_y
	
	# Limita para não descer demais (não vai abaixo da sala inicial)
	if camera_target_y > 640:  # Centro da primeira sala
		camera_target_y = 640
	
	# Atualiza posição da câmera (com shake aplicado)
	global_position.y = camera_target_y + offset.y
	
	# Verifica se player atingiu nova altura máxima
	if target_y < highest_y_reached:
		highest_y_reached = target_y
		check_and_generate_rooms()

func apply_shake(delta):
	"""Aplica o efeito de tremor"""
	if shake_timer > 0:
		shake_timer -= delta
		
		# Cria tremor aleatório
		var shake_offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		
		offset = shake_offset
		
		# Decai a força do shake ao longo do tempo
		shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)
	else:
		# Reseta offset quando não há shake
		offset = Vector2.ZERO
		shake_strength = 0.0

func shake(duration: float, strength: float = 30.0):
	"""Inicia o tremor da câmera"""
	shake_timer = duration
	shake_strength = strength
	print("📹 Camera shake iniciado - Força: ", strength, " Duração: ", duration)

func check_and_generate_rooms():
	"""Verifica se precisa gerar novas salas acima"""
	var rooms_climbed = int(abs((highest_y_reached - 960) / ROOM_HEIGHT))
	
	if main_scene and main_scene.has_method("generate_rooms_ahead"):
		main_scene.generate_rooms_ahead(rooms_climbed)
