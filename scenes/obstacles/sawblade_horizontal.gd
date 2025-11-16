# sawblade_horizontal.gd
extends Area2D

enum Speed { FAST, FASTER, FASTEST }

var speed = 0.0
var direction = 1  # 1 = direita, -1 = esquerda

# Velocidades (todas rápidas)
const SPEED_FAST = 250.0
const SPEED_FASTER = 350.0
const SPEED_FASTEST = 450.0

# Limites horizontais
const MARGIN = 50
const ROOM_WIDTH = 720

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	collision_layer = 4
	collision_mask = 1
	
	body_entered.connect(_on_body_entered)
	
	# Inicia a animação de rotação
	if animated_sprite:
		animated_sprite.play("spin")  # Ajuste o nome da animação
	
	# Define velocidade aleatória
	randomize_speed()
	
	# Direção inicial aleatória
	if randf() > 0.5:
		direction = -1

func _physics_process(delta):
	# Movimento horizontal
	position.x += direction * speed * delta
	
	# Verifica limites e inverte direção
	if position.x <= MARGIN:
		direction = 1
		position.x = MARGIN
	elif position.x >= ROOM_WIDTH - MARGIN:
		direction = -1
		position.x = ROOM_WIDTH - MARGIN

func randomize_speed():
	"""Define velocidade aleatória (todas rápidas)"""
	var speed_type = randi() % 3
	
	match speed_type:
		0:
			speed = SPEED_FAST
			print("🪚 Sawblade Horizontal - Velocidade: RÁPIDA (", speed, ")")
		1:
			speed = SPEED_FASTER
			print("🪚 Sawblade Horizontal - Velocidade: MAIS RÁPIDA (", speed, ")")
		2:
			speed = SPEED_FASTEST
			print("🪚 Sawblade Horizontal - Velocidade: ULTRA RÁPIDA (", speed, ")")

func _on_body_entered(body):
	"""Detecta colisão com o player"""
	if body.name == "Player" and body.has_method("take_damage"):
		body.take_damage(self)
		print("🪚 Sawblade Horizontal atingiu o player!")
