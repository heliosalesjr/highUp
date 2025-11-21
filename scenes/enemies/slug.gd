# slug.gd
extends CharacterBody2D

@export var min_speed = 50.0
@export var max_speed = 150.0

var speed = 0.0
var direction = 1

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	collision_layer = 8
	collision_mask = 49
	
	randomize_speed()
	
	if randf() > 0.5:
		direction = -1
	
	update_sprite_flip()
	
	var hitbox = get_node_or_null("HitBox")
	if hitbox:
		hitbox.body_entered.connect(_on_body_entered)
		print("🐌 Slug HitBox configurado")
	else:
		print("⚠️ AVISO: HitBox não encontrado na Slug!")

func _physics_process(delta):
	velocity.x = direction * speed
	
	if not is_on_floor():
		velocity.y += 980 * delta
	else:
		velocity.y = 0
	
	move_and_slide()
	
	if is_on_wall():
		reverse_direction()
	
	update_sprite_flip()

func reverse_direction():
	direction *= -1

func update_sprite_flip():
	if animated_sprite:
		animated_sprite.flip_h = direction > 0

func randomize_speed():
	speed = randf_range(min_speed, max_speed)
	print("🐌 Slug criada com velocidade: ", speed)

func _on_body_entered(body):
	"""Detecta colisão com o player"""
	if body.name == "Player" and body.has_method("take_damage"):
		# Verifica se o player está em modo de lançamento  ← NOVO
		if body.is_launched:
			print("🐌 Slug ignorou player lançado")
			return
		
		body.take_damage(self)
		print("🐌 Slug atingiu o player!")
