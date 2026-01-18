# capy.gd
extends Node2D

@export var min_speed = 25.0
@export var max_speed = 75.0

var speed = 0.0
var direction = 1
var is_being_freed = false
var fixed_y = 0.0  # Posição Y fixa (sem gravidade)

@onready var animated_sprite = $AnimatedSprite2D
@onready var hitbox = $HitBox
@onready var wall_detector = $WallDetector

func _ready():
	randomize_speed()

	# Salva a posição Y do spawn - vai ficar fixa
	fixed_y = global_position.y

	if randf() > 0.5:
		direction = -1

	update_sprite_flip()
	update_wall_detector_direction()

	if hitbox:
		hitbox.body_entered.connect(_on_body_entered)
		print("🦫 Capy HitBox configurado")
	else:
		print("⚠️ AVISO: HitBox não encontrado na Capy!")

func _process(delta):
	# Se está sendo libertado, não aplica movimento normal
	if is_being_freed:
		return

	# Mantém posição Y fixa (preso ao chão)
	global_position.y = fixed_y

	# Movimento horizontal
	global_position.x += direction * speed * delta

	# Atualiza RayCast e detecta parede
	wall_detector.force_raycast_update()
	if wall_detector.is_colliding():
		reverse_direction()

	update_sprite_flip()

func reverse_direction():
	direction *= -1
	update_wall_detector_direction()
	print("🦫 Capy inverteu direção")

func update_wall_detector_direction():
	"""Atualiza a direção do RayCast de parede baseado na direção do movimento"""
	if wall_detector:
		wall_detector.target_position = Vector2(30 * direction, 0)

func update_sprite_flip():
	if animated_sprite:
		animated_sprite.flip_h = direction < 0

func randomize_speed():
	speed = randf_range(min_speed, max_speed)
	print("🦫 Capy criada com velocidade: ", speed)

func _on_body_entered(body):
	"""Detecta colisão com o player"""
	if body.name == "Player" and body.has_method("take_damage"):
		# Ignora se player está lançado
		if body.is_launched:
			print("🦫 Capy ignorou player lançado")
			return

		# Verifica se player está no modo metal OU invincible
		if GameManager.metal_mode_active or GameManager.invincible_mode_active:
			be_freed()
			return

		# Dano normal
		body.take_damage(self)
		print("🦫 Capy atingiu o player!")

func be_freed():
	"""Animal é libertado pelo modo metal"""
	if is_being_freed:
		return

	is_being_freed = true
	print("🦋 Capy sendo LIBERTADA!")

	# Camera shake ao libertar
	trigger_camera_shake()

	GameManager.free_animal("Capy")

func trigger_camera_shake():
	"""Ativa camera shake ao acertar inimigo (modo metal)"""
	var camera = get_tree().get_first_node_in_group("camera")
	if camera and camera.has_method("shake"):
		camera.shake(0.2, 10.0)

	# Desabilita HitBox
	if hitbox:
		hitbox.collision_mask = 0
		hitbox.collision_layer = 0

	# Efeito visual de libertação
	liberation_effect()

func liberation_effect():
	"""Efeito visual de libertação - pulinho de alegria e corre para fora da tela"""
	var tween = create_tween()
	var original_y = global_position.y

	# Brilho dourado
	tween.tween_property(animated_sprite, "modulate", Color(2.0, 2.0, 1.0), 0.3)

	# Pulinho de alegria (sobe e volta ao chão)
	tween.tween_property(self, "global_position:y", original_y - 15, 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position:y", original_y, 0.15).set_ease(Tween.EASE_IN)
	# Segundo pulinho menor
	tween.tween_property(self, "global_position:y", original_y - 8, 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position:y", original_y, 0.1).set_ease(Tween.EASE_IN)

	# Calcula posição fora da tela
	var room_width = 360
	var exit_x = room_width + 50 if direction > 0 else -50

	# Corre para fora da tela (só eixo X)
	tween.tween_property(self, "global_position:x", exit_x, 1.5).set_ease(Tween.EASE_IN)

	tween.finished.connect(func():
		print("🦫 Capy saiu da tela e foi removida")
		queue_free()
	)
