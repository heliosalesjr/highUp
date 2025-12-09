# bird.gd
extends CharacterBody2D

enum Speed { MEDIUM, FAST, ULTRA_FAST }

var speed = 0.0
var direction = -1  # -1 = esquerda (direção inicial)
var is_being_freed = false  # ← NOVO

# Velocidades ajustadas
const SPEED_MEDIUM = 100.0
const SPEED_FAST = 175.0
const SPEED_ULTRA_FAST = 250.0

@onready var animated_sprite = $AnimatedSprite2D

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
	# Se está sendo libertado, não aplica física normal
	if is_being_freed:
		return

	velocity.x = direction * speed
	velocity.y = 0

	move_and_slide()

	# Detecta colisão com parede e inverte direção
	if is_on_wall():
		direction *= -1
		print("🦅 Bird bateu na parede e inverteu direção")

	check_boundaries()
	update_sprite_flip()

func check_boundaries():
	"""Verifica se atingiu as paredes e inverte direção"""
	var room_width = 360
	var margin = 5
	
	if global_position.x <= margin:
		direction = 1
		print("🦅 Bird virou para direita")
	
	elif global_position.x >= room_width - margin:
		direction = -1
		print("🦅 Bird virou para esquerda")

func update_sprite_flip():
	"""Atualiza o flip do AnimatedSprite2D baseado na direção"""
	if animated_sprite:
		animated_sprite.flip_h = direction > 0

func randomize_speed():
	"""Define velocidade aleatória"""
	var speed_type = randi() % 3
	
	match speed_type:
		0:
			speed = SPEED_MEDIUM
			print("🦅 Bird criado - Velocidade: MÉDIA (", speed, ")")
		1:
			speed = SPEED_FAST
			print("🦅 Bird criado - Velocidade: RÁPIDA (", speed, ")")
		2:
			speed = SPEED_ULTRA_FAST
			print("🦅 Bird criado - Velocidade: ULTRA RÁPIDA (", speed, ")")

func _on_body_entered(body):
	"""Detecta colisão com o player"""
	if body.name == "Player" and body.has_method("take_damage"):
		# Verifica se player está lançado
		if body.is_launched:
			print("🦅 Bird ignorou player lançado")
			return
		
		# Verifica se player está no modo metal
		if GameManager.metal_mode_active:
			be_freed()
			return
		
		# Dano normal
		body.take_damage(self)
		print("🦅 Bird atingiu o player!")

func be_freed():
	"""Animal é libertado pelo modo metal"""
	if is_being_freed:
		return
	
	is_being_freed = true
	print("🦋 Bird sendo LIBERTADO!")
	
	GameManager.free_animal("Bird")
	
	# Desabilita colisão
	collision_layer = 0
	collision_mask = 0
	
	var hitbox = get_node_or_null("HitBox")
	if hitbox:
		hitbox.collision_mask = 0
	
	# Efeito visual de libertação
	liberation_effect()

func liberation_effect():
	"""Efeito visual de libertação - SOBE e depois VOA para fora da tela"""
	var tween = create_tween()
	
	# Brilho dourado
	tween.tween_property(animated_sprite, "modulate", Color(2.0, 2.0, 1.0), 0.3)
	
	# Fase 1: SOBE (pequeno impulso)
	tween.tween_property(self, "global_position:y", global_position.y - 50, 0.4).set_ease(Tween.EASE_OUT)
	
	# Calcula posição fora da tela
	var room_width = 360
	var exit_x = room_width + 75 if direction > 0 else -75
	var exit_y = global_position.y - 300  # Voa bem alto
	
	# Fase 2: VOA para fora da tela (para cima E para o lado)
	tween.set_parallel(true)
	tween.tween_property(self, "global_position:y", exit_y, 2.0).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position:x", exit_x, 2.0).set_ease(Tween.EASE_IN_OUT)
	
	# SEM fade out - só remove quando terminar
	tween.set_parallel(false)
	tween.finished.connect(func():
		print("🦅 Bird voou para fora da tela e foi removido")
		queue_free()
	)
