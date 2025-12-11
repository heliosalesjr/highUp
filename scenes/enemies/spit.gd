# spit.gd
extends CharacterBody2D

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

func _ready():
	collision_layer = 0  # Sem colisão física (evita ser empurrado pelo player)
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

	# Verifica se o player está muito próximo e empurra o Spit para o lado
	check_player_proximity()

	# Aplica gravidade para ficar no chão
	if not is_on_floor():
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta
	else:
		velocity.y = 0

	# Aplica fricção na velocidade horizontal
	if is_on_floor() and abs(velocity.x) > 0:
		velocity.x = move_toward(velocity.x, 0, 300 * delta)

	move_and_slide()

	# Sistema de cuspe - APENAS UMA VEZ
	if player_in_room and not is_being_freed and not has_spit:
		spit_timer -= delta
		if spit_timer <= 0:
			shoot_projectile()
			has_spit = true  # Marca que já cuspiu

func check_player_proximity():
	"""Detecta se o player está muito próximo e empurra o Spit para o lado"""
	var player = get_tree().get_first_node_in_group("player")
	if not player or is_being_freed:
		return

	var distance_to_player = global_position.distance_to(player.global_position)
	var horizontal_distance = abs(global_position.x - player.global_position.x)
	var vertical_distance = global_position.y - player.global_position.y

	# Se o player está muito próximo (especialmente acima do Spit)
	if distance_to_player < 50 and vertical_distance > -20:
		# Determina a direção para empurrar o Spit (lado oposto ao player)
		var push_direction = -1 if player.global_position.x > global_position.x else 1

		# Aplica impulso horizontal para afastar o Spit
		velocity.x = push_direction * 200

		# Se o player está praticamente em cima, também dá um pequeno impulso para cima
		if vertical_distance > -10 and horizontal_distance < 15:
			velocity.y = -150
			print("🐸 Spit se afastando! Player está muito próximo!")

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

	# Desabilita colisão
	collision_layer = 0
	collision_mask = 0

	var hitbox = get_node_or_null("HitBox")
	if hitbox:
		hitbox.collision_mask = 0

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
