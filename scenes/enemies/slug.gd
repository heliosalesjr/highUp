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
		# Ignora se player está lançado
		if body.is_launched:
			print("🐌 Slug ignorou player lançado")
			return
		
		# Verifica se player está no modo metal  ← CORRIGIDO
		if GameManager.metal_mode_active:
			be_freed()  # Liberta o animal!
			return
		
		# Dano normal
		body.take_damage(self)
		print("🐌 Slug atingiu o player!")

func be_freed():
	"""Animal é libertado pelo modo metal"""
	print("🦋 Slug sendo LIBERTADO!")
	
	GameManager.free_animal("Slug")
	
	# Desabilita colisão
	collision_layer = 0
	collision_mask = 0
	
	var hitbox = get_node_or_null("HitBox")
	if hitbox:
		hitbox.collision_mask = 0
	
	# Efeito visual de libertação
	liberation_effect()

func liberation_effect():
	"""Efeito visual de libertação"""
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Brilho dourado
	tween.tween_property(animated_sprite, "modulate", Color(2.0, 2.0, 1.0), 0.3)
	
	# Voa para cima e para fora
	tween.tween_property(self, "global_position:y", global_position.y - 200, 1.5)
	tween.tween_property(self, "global_position:x", global_position.x + (direction * 150), 1.5)
	
	# Fade out
	tween.chain().tween_property(self, "modulate:a", 0.0, 0.5)
	
	# Remove da cena
	tween.finished.connect(queue_free)
