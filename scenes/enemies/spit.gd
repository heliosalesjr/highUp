# spit.gd
extends CharacterBody2D

var is_being_freed = false
var player_in_room = false
var direction = -1  # -1 = esquerda, 1 = direita

# Timer para cuspir
var spit_timer = 0.0
const SPIT_INTERVAL = 2.0  # Cuspe a cada 2 segundos

# Cena do projétil
var projectile_scene = preload("res://scenes/enemies/spit_projectile.tscn")

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	collision_layer = 8  # Layer de inimigos
	collision_mask = 1   # Colide com chão/paredes

	# Configurar HitBox
	var hitbox = get_node_or_null("HitBox")
	if hitbox:
		hitbox.body_entered.connect(_on_body_entered)
		print("🐸 Spit HitBox configurado")
	else:
		print("⚠️ AVISO: HitBox não encontrado no Spit!")

func _physics_process(delta):
	if is_being_freed:
		return

	# Aplica gravidade para ficar no chão
	if not is_on_floor():
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta
	else:
		velocity.y = 0

	velocity.x = 0  # Spit não se move horizontalmente
	move_and_slide()

	# Sistema de cuspe
	if player_in_room and not is_being_freed:
		spit_timer -= delta
		if spit_timer <= 0:
			shoot_projectile()
			spit_timer = SPIT_INTERVAL

func set_direction(dir: int):
	"""Define a direção do spit (1 = direita, -1 = esquerda)"""
	direction = dir
	if animated_sprite:
		animated_sprite.flip_h = (direction > 0)
	print("🐸 Spit virado para ", "direita" if direction > 0 else "esquerda")

func on_player_entered_room():
	"""Chamado quando o player entra na room"""
	player_in_room = true
	spit_timer = SPIT_INTERVAL * 0.5  # Primeiro tiro em 1 segundo
	print("🐸 Spit detectou player! Começando a cuspir...")

func shoot_projectile():
	"""Dispara um projétil na direção do player"""
	if is_being_freed:
		return

	var projectile = projectile_scene.instantiate()

	# Define direção ANTES de adicionar à árvore
	projectile.direction = direction

	# Adiciona à árvore primeiro
	get_parent().add_child(projectile)

	# DEPOIS seta global_position (precisa estar na árvore primeiro)
	var offset_x = 15 * direction
	projectile.global_position = global_position + Vector2(offset_x, -10)

	print("🐸 CUSPE! pos=", projectile.global_position, " dir=", direction)

func _on_body_entered(body):
	"""Detecta colisão com o player"""
	if body.name == "Player" and body.has_method("take_damage"):
		# Verifica se player está lançado
		if body.is_launched:
			print("🐸 Spit ignorou player lançado")
			return

		# Verifica se player está no modo metal
		if GameManager.metal_mode_active:
			be_freed()
			return

		# Dano normal
		body.take_damage(self)
		print("🐸 Spit atingiu o player!")

func be_freed():
	"""Animal é libertado pelo modo metal"""
	if is_being_freed:
		return

	is_being_freed = true
	print("🐸 Spit sendo LIBERTADO!")

	GameManager.free_animal("Spit")

	# Desabilita colisão
	collision_layer = 0
	collision_mask = 0

	var hitbox = get_node_or_null("HitBox")
	if hitbox:
		hitbox.collision_mask = 0

	# Efeito visual de libertação
	liberation_effect()

func liberation_effect():
	"""Efeito visual de libertação - PULA e some"""
	var tween = create_tween()

	# Brilho dourado
	tween.tween_property(animated_sprite, "modulate", Color(2.0, 2.0, 1.0), 0.3)

	# Pula para cima
	tween.tween_property(self, "global_position:y", global_position.y - 100, 0.6).set_ease(Tween.EASE_OUT)

	# Fade out
	tween.set_parallel(true)
	tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.4)

	tween.set_parallel(false)
	tween.finished.connect(func():
		print("🐸 Spit libertado e removido")
		queue_free()
	)
