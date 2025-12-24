# spike.gd
extends Area2D

# Spike é um obstacle estático grudado na parede
# Pode ser configurado para apontar para esquerda ou direita

@export var flip_h = false  # Espelha horizontalmente (muda direção)

@onready var sprite = $Sprite2D

func _ready():
	collision_layer = 4  # Layer de obstacles que causam dano
	collision_mask = 1   # Detecta player

	body_entered.connect(_on_body_entered)

	# Aplica flip se configurado
	if sprite and flip_h:
		sprite.flip_h = true

	print("🔺 Spike criado em: ", global_position, " | Flip: ", flip_h)

func _on_body_entered(body):
	"""Detecta colisão com o player"""
	if body.name == "Player" and body.has_method("take_damage"):
		# Ignora se player está invencível
		if GameManager.invincible_mode_active:
			print("🔺 Spike ignorou player invencível!")
			return

		body.take_damage(self)
		print("🔺 Spike atingiu o player!")
