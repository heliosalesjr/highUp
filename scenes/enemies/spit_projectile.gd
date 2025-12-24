# spit_projectile.gd
extends Area2D

var direction = -1
var speed = 300.0  # Velocidade aumentada (era 150)
var lifetime = 5.0  # Remove após 5 segundos se não acertar nada

func _ready():
	collision_layer = 8  # Layer de inimigos
	collision_mask = 1   # Detecta player e paredes

	body_entered.connect(_on_body_entered)

	# Auto-destruição após lifetime
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(delta):
	# Move o projétil na direção
	global_position.x += direction * speed * delta

func set_direction(dir: int):
	"""Define a direção do projétil"""
	direction = dir

func _on_body_entered(body):
	"""Detecta colisão"""
	# Se colidiu com parede, remove
	if body is StaticBody2D:
		print("💧 Projétil bateu na parede")
		queue_free()
		return

	# Se colidiu com player
	if body.name == "Player" and body.has_method("take_damage"):
		# Ignora se player está lançado ou invulnerável
		if body.is_launched or body.is_invulnerable or body.launch_invulnerability:
			print("💧 Projétil ignorou player protegido")
			return

		# Ignora se player está no modo invincible
		if GameManager.invincible_mode_active:
			print("💧 Projétil ignorou player invencível!")
			queue_free()  # Projétil se destrói ao tocar player invencível
			return

		# Causa dano
		body.take_damage(self)
		print("💧 Projétil acertou o player!")
		queue_free()
