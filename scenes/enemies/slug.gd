# slug.gd
extends CharacterBody2D

@export var min_speed = 50.0
@export var max_speed = 150.0

var speed = 0.0
var direction = 1

@onready var animated_sprite = $AnimatedSprite2D  # ← NOVO

func _ready():
	collision_layer = 8
	collision_mask = 49
	
	randomize_speed()
	
	if randf() > 0.5:
		direction = -1
	
	# Aplica flip inicial
	update_sprite_flip()  # ← NOVO
	
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
	
	update_sprite_flip()  # ← NOVO: Atualiza flip a cada frame

func reverse_direction():
	direction *= -1

func update_sprite_flip():  # ← FUNÇÃO NOVA
	"""Atualiza o flip do AnimatedSprite2D baseado na direção"""
	if animated_sprite:
		# Ajuste baseado na direção original da sua sprite:
		# Se a sprite original aponta para DIREITA: flip_h = direction < 0
		# Se a sprite original aponta para ESQUERDA: flip_h = direction > 0
		
		# Assumindo que a sprite original aponta para DIREITA:
		animated_sprite.flip_h = direction > 0

func randomize_speed():
	speed = randf_range(min_speed, max_speed)
	print("🐌 Slug criada com velocidade: ", speed)

func _on_body_entered(body):
	"""Detecta colisão com o player"""
	if body.name == "Player" and body.has_method("take_damage"):
		body.take_damage(self)
		print("🐌 Slug atingiu o player!")
