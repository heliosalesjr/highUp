extends Camera2D

@export var target: Node2D  # O player
@export var smoothing_enabled = true
@export var smoothing_speed = 5.0

const ROOM_HEIGHT = 320
var fixed_x_position = 360  # Meio da tela (720 / 2)
var highest_y_reached = 1280  # Começa no bottom

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

func _process(_delta):
	if not target:
		return
	
	# Segue o player apenas no eixo Y
	# A câmera centraliza o player verticalmente na tela
	var target_y = target.global_position.y
	
	# Só move a câmera se o player subir acima do centro da tela
	var camera_target_y = target_y
	
	# Limita para não descer demais (não vai abaixo da sala inicial)
	if camera_target_y > 640:  # Centro da primeira sala
		camera_target_y = 640
	
	# Atualiza posição da câmera
	global_position.y = camera_target_y
	
	# Verifica se player atingiu nova altura máxima
	if target_y < highest_y_reached:
		highest_y_reached = target_y
		check_and_generate_rooms()

func check_and_generate_rooms():
	"""Verifica se precisa gerar novas salas acima"""
	
	# Calcula qual sala o player está
	var current_room_index = int(abs(highest_y_reached) / ROOM_HEIGHT)
	
	# Se o player está subindo, gera salas à frente
	if main_scene and main_scene.has_method("generate_rooms_ahead"):
		main_scene.generate_rooms_ahead(current_room_index)
