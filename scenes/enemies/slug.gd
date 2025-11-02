# slug.gd
extends CharacterBody2D

@export var min_speed = 50.0
@export var max_speed = 150.0

var speed = 0.0
var direction = 1

func _ready():
	# Configura collision
	collision_layer = 8  # Layer de inimigos
	collision_mask = 49  # Detecta: player (1) + paredes (16) + chão inimigos (32) = 1+16+32=49
	
	randomize_speed()
	
	if randf() > 0.5:
		direction = -1

func _physics_process(delta):
	velocity.x = direction * speed
	
	# Aplica gravidade
	if not is_on_floor():
		velocity.y += 980 * delta
	else:
		velocity.y = 0
	
	move_and_slide()
	
	if is_on_wall():
		reverse_direction()

func reverse_direction():
	direction *= -1

func randomize_speed():
	speed = randf_range(min_speed, max_speed)
	print("🐌 Slug criada com velocidade: ", speed)
