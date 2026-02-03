# camera_2d.gd
extends Camera2D

@export var target: Node2D  # O player
@export var smoothing_enabled = true
@export var smoothing_speed = 5.0

const ROOM_HEIGHT = 160

var fixed_x_position = 180
var highest_y_reached = 800  # Começa mais embaixo para a intro

# Shake variables
var is_shaking = false
var shake_intensity = 0.0
var shake_time_remaining = 0.0
var original_offset = Vector2.ZERO

var is_locked = false

# Referência para a Main
var main_scene: Node2D

func _ready():

	add_to_group("camera")

	position.x = fixed_x_position
	zoom = Vector2(1, 1)
	position_smoothing_enabled = smoothing_enabled
	position_smoothing_speed = smoothing_speed
	main_scene = get_parent()

	# Inicia mais embaixo para a cutscene de entrada
	# A câmera vai seguir o player subindo
	global_position.y = 500

func _process(delta):
	if not target:
		return

	if is_locked:
		process_shake(delta)
		return

	# SHAKE primeiro
	process_shake(delta)

	# Segue o player apenas no eixo Y
	var target_y = target.global_position.y
	var camera_target_y = target_y

	# Limita a câmera para não descer demais (floor da room 0 no centro)
	# O floor está em Y=320, então a câmera não deve ir abaixo de 320
	if camera_target_y > 320:
		camera_target_y = 320

	# Atualiza posição da câmera
	global_position.y = camera_target_y
	
	# Verifica se player atingiu nova altura máxima
	if target_y < highest_y_reached:
		highest_y_reached = target_y
		check_and_generate_rooms()

func process_shake(delta):
	"""Processa o shake da câmera"""
	if is_shaking:
		shake_time_remaining -= delta

		if shake_time_remaining > 0:
			# Aplica shake no offset
			offset = Vector2(
				randf_range(-shake_intensity, shake_intensity),
				randf_range(-shake_intensity, shake_intensity)
			)

			# Diminui intensidade gradualmente
			shake_intensity = lerp(shake_intensity, 0.0, delta * 3.0)
		else:
			# Termina o shake
			is_shaking = false
			offset = Vector2.ZERO
			shake_intensity = 0.0
	else:
		offset = Vector2.ZERO

func shake(duration: float, intensity: float = 25.0):
	"""Inicia o shake da câmera"""
	is_shaking = true
	shake_time_remaining = duration
	shake_intensity = intensity

func check_and_generate_rooms():
	"""Verifica se precisa gerar novas salas acima"""
	# Base é o floor da room 0 (Y = 320)
	var base_floor_y = 320
	var rooms_climbed = int(abs((highest_y_reached - base_floor_y) / ROOM_HEIGHT))

	if main_scene and main_scene.has_method("generate_rooms_ahead"):
		main_scene.generate_rooms_ahead(rooms_climbed)
