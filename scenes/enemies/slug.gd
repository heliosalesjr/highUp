# slug.gd
extends Node2D

@export var min_speed = 25.0
@export var max_speed = 75.0

var speed = 0.0
var direction = 1
var is_being_freed = false
var vertical_velocity = 0.0  # Para simular gravidade

const GRAVITY = 980.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var hitbox = $HitBox
@onready var floor_detector = $FloorDetector
@onready var wall_detector = $WallDetector

func _ready():
	randomize_speed()

	if randf() > 0.5:
		direction = -1

	update_sprite_flip()
	update_wall_detector_direction()

	if hitbox:
		hitbox.body_entered.connect(_on_body_entered)
		print("🐌 Slug HitBox configurado (SEM colisão física - apenas detecção)")
	else:
		print("⚠️ AVISO: HitBox não encontrado na Slug!")

func _process(delta):
	# Se está sendo libertado, não aplica movimento normal
	if is_being_freed:
		return

	# Atualiza RayCasts
	floor_detector.force_raycast_update()
	wall_detector.force_raycast_update()

	# Aplica "gravidade" se não está no chão
	if not floor_detector.is_colliding():
		vertical_velocity += GRAVITY * delta
		global_position.y += vertical_velocity * delta
	else:
		# Gruda no chão (collision agora está no topo do piso)
		vertical_velocity = 0
		var collision_point = floor_detector.get_collision_point()
		# Como a collision está no topo, basta subtrair a altura do sprite/hitbox
		global_position.y = collision_point.y - 8  # Ajustado para alinhar com o topo do piso

	# Movimento horizontal
	global_position.x += direction * speed * delta

	# Detecta parede e inverte direção
	if wall_detector.is_colliding():
		reverse_direction()

	update_sprite_flip()

func reverse_direction():
	direction *= -1
	update_wall_detector_direction()
	print("🐌 Slug inverteu direção")

func update_wall_detector_direction():
	"""Atualiza a direção do RayCast de parede baseado na direção do movimento"""
	if wall_detector:
		wall_detector.target_position = Vector2(15 * direction, 0)

func update_sprite_flip():
	if animated_sprite:
		animated_sprite.flip_h = direction > 0

func randomize_speed():
	speed = randf_range(min_speed, max_speed)
	print("🐌 Slug criada com velocidade: ", speed)

func _on_body_entered(body):
	"""Detecta colisão com o player"""
	if body.name == "Player" and body.has_method("take_damage"):
		# Ignora se player está lançado
		if body.is_launched:
			print("🐌 Slug ignorou player lançado")
			return

		# Verifica se player está no modo metal OU invincible
		if GameManager.metal_mode_active or GameManager.invincible_mode_active:
			be_freed()
			return

		# Dano normal
		body.take_damage(self)
		print("🐌 Slug atingiu o player!")

func be_freed():
	"""Animal é libertado pelo modo metal"""
	if is_being_freed:
		return

	is_being_freed = true
	print("🦋 Slug sendo LIBERTADO!")

	# Camera shake ao libertar
	trigger_camera_shake()

	GameManager.free_animal("Slug")

func trigger_camera_shake():
	"""Ativa camera shake ao acertar inimigo (modo metal)"""
	var camera = get_tree().get_first_node_in_group("camera")
	if camera and camera.has_method("shake"):
		camera.shake(0.2, 10.0)  # Duração: 0.2s, intensidade: 10 (sutil)

	# Desabilita HitBox (não há mais colisão física para desabilitar)
	if hitbox:
		hitbox.collision_mask = 0
		hitbox.collision_layer = 0

	# Efeito visual de libertação
	liberation_effect()

func liberation_effect():
	"""Efeito visual de libertação - tremidinha e corre para fora da tela"""
	var tween = create_tween()

	# Brilho dourado
	tween.tween_property(animated_sprite, "modulate", Color(2.0, 2.0, 1.0), 0.3)

	# Tremidinha (shake horizontal)
	var original_x = global_position.x
	tween.tween_property(self, "global_position:x", original_x + 3, 0.05)
	tween.tween_property(self, "global_position:x", original_x - 3, 0.05)
	tween.tween_property(self, "global_position:x", original_x + 2, 0.05)
	tween.tween_property(self, "global_position:x", original_x - 2, 0.05)
	tween.tween_property(self, "global_position:x", original_x, 0.05)

	# Calcula posição fora da tela
	var room_width = 360
	var exit_x = room_width + 50 if direction > 0 else -50

	# Corre para fora da tela (só eixo X)
	tween.tween_property(self, "global_position:x", exit_x, 1.5).set_ease(Tween.EASE_IN)

	tween.finished.connect(func():
		print("🐌 Slug saiu da tela e foi removido")
		queue_free()
	)
