# bird.gd
extends CharacterBody2D

enum Speed { MEDIUM, FAST, ULTRA_FAST }

var speed = 0.0
var direction = -1  # -1 = esquerda (direção inicial)

# Velocidades ajustadas (mais rápidas)
const SPEED_MEDIUM = 200.0
const SPEED_FAST = 350.0
const SPEED_ULTRA_FAST = 500.0

@onready var animated_sprite = $AnimatedSprite2D  # ← MUDOU

func _ready():
	collision_layer = 8
	collision_mask = 1
	
	randomize_speed()
	
	var hitbox = get_node_or_null("HitBox")
	if hitbox:
		hitbox.body_entered.connect(_on_body_entered)
		print("🦅 Bird HitBox configurado")
	else:
		print("⚠️ AVISO: HitBox não encontrado no Bird!")

func _physics_process(delta):
	velocity.x = direction * speed
	velocity.y = 0
	
	move_and_slide()
	
	check_boundaries()
	update_sprite_flip()

func check_boundaries():
	"""Verifica se atingiu as paredes e inverte direção"""
	var room_width = 720
	var margin = 50
	
	if global_position.x <= margin:
		direction = 1
		print("🦅 Bird virou para direita")
	
	elif global_position.x >= room_width - margin:
		direction = -1
		print("🦅 Bird virou para esquerda")

func update_sprite_flip():
	"""Atualiza o flip do AnimatedSprite2D baseado na direção"""
	if animated_sprite:
		# Sprite original aponta para esquerda (direction = -1)
		# direction = -1 → flip_h = false (normal)
		# direction = 1 → flip_h = true (flipado)
		animated_sprite.flip_h = direction > 0

func randomize_speed():
	"""Define velocidade aleatória (3 opções mais rápidas)"""
	var speed_type = randi() % 3  # 0, 1 ou 2
	
	match speed_type:
		0:  # Médio
			speed = SPEED_MEDIUM
			print("🦅 Bird criado - Velocidade: MÉDIA (", speed, ")")
		1:  # Rápido
			speed = SPEED_FAST
			print("🦅 Bird criado - Velocidade: RÁPIDA (", speed, ")")
		2:  # Ultra rápido
			speed = SPEED_ULTRA_FAST
			print("🦅 Bird criado - Velocidade: ULTRA RÁPIDA (", speed, ")")

func _on_body_entered(body):
	"""Detecta colisão com o player"""
	if body.name == "Player" and body.has_method("take_damage"):
		# Verifica se o player está em modo de lançamento  ← NOVO
		if body.is_launched:
			print("🦅 Bird ignorou player lançado")
			return
		
		body.take_damage(self)
		print("🦅 Bird atingiu o player!")
