# spit.gd
extends Node2D

var is_being_freed = false
var player_in_room = false
var direction = -1  # -1 = esquerda, 1 = direita
var has_spit = false  # Controla se já cuspiu

# Timer para cuspir
var spit_timer = 0.0
const SPIT_INTERVAL = 2.0  # Cuspe a cada 2 segundos

# Cena do projétil
var projectile_scene = preload("res://scenes/enemies/spit_projectile.tscn")

@onready var animated_sprite = $AnimatedSprite2D
@onready var floor_detector = $FloorDetector
@onready var hitbox = $HitBox

func _ready():
	# Posiciona o Spit no chão
	snap_to_floor()

	# Configurar HitBox
	if hitbox:
		hitbox.body_entered.connect(_on_body_entered)
		print("🐸 Spit HitBox configurado (SEM colisão física - apenas detecção)")
	else:
		print("⚠️ AVISO: HitBox não encontrado no Spit!")

func snap_to_floor():
	"""Posiciona o Spit no chão usando RayCast2D"""
	if not floor_detector:
		return

	floor_detector.force_raycast_update()

	if floor_detector.is_colliding():
		var collision_point = floor_detector.get_collision_point()
		global_position.y = collision_point.y - 13  # Ajusta para ficar em cima do chão (metade da altura do Spit)
		print("🐸 Spit posicionado no chão em y=", global_position.y)
	else:
		print("⚠️ Spit não encontrou chão abaixo!")

func _process(delta):
	if is_being_freed:
		return

	# Sistema de cuspe - APENAS UMA VEZ
	if player_in_room and not is_being_freed and not has_spit:
		spit_timer -= delta
		if spit_timer <= 0:
			shoot_projectile()
			has_spit = true  # Marca que já cuspiu

func set_direction(dir: int):
	"""Define a direção do spit (1 = direita, -1 = esquerda)"""
	direction = dir
	if animated_sprite:
		animated_sprite.flip_h = (direction < 0)
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

	# Desabilita HitBox (não há mais colisão física para desabilitar)
	if hitbox:
		hitbox.collision_mask = 0
		hitbox.collision_layer = 0

	# Efeito visual de libertação
	liberation_effect()

func liberation_effect():
	"""Efeito visual de libertação - TREME e SAI para o lado"""
	var tween = create_tween()

	# Determina para qual lado sair baseado na posição
	# Se está do lado esquerdo da tela, sai para a direita (e vice-versa)
	var room_width = 360
	var escape_direction = 1 if global_position.x < room_width / 2 else -1

	# Vira o sprite para a direção de fuga
	if animated_sprite:
		animated_sprite.flip_h = (escape_direction < 0)

	print("🐸 Spit fugindo para ", "direita" if escape_direction > 0 else "esquerda")

	# Brilho dourado
	tween.tween_property(animated_sprite, "modulate", Color(2.0, 2.0, 1.0), 0.3)

	# Fase 1: TREMIDINHA (pequenos movimentos rápidos)
	var shake_amount = 3
	for i in range(6):  # 6 tremidas
		var shake_x = shake_amount if i % 2 == 0 else -shake_amount
		tween.tween_property(self, "global_position:x", global_position.x + shake_x, 0.05)

	# Calcula posição fora da tela
	var exit_x = room_width + 50 if escape_direction > 0 else -50

	# Fase 2: SAI CORRENDO para o lado
	tween.tween_property(self, "global_position:x", exit_x, 1.5).set_ease(Tween.EASE_IN)

	# Remove quando terminar
	tween.finished.connect(func():
		print("🐸 Spit escapou e foi removido")
		queue_free()
	)
