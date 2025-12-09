# cannon.gd
extends Area2D

signal player_launched(player)

const LAUNCH_VELOCITY = -1200.0  # Velocidade para subir ~5 salas

func _ready():
	collision_layer = 4  # Layer de obstáculos
	collision_mask = 1   # Detecta player
	
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player" and body.has_method("launch_from_cannon"):
		body.launch_from_cannon(LAUNCH_VELOCITY)
		play_launch_effect()
		print("🚀 Canhão lançou o player!")

func play_launch_effect():
	"""Efeito visual do canhão (opcional)"""
	# Aqui você pode adicionar partículas, som, animação, etc.
	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate", Color(1.5, 1.5, 1.5), 0.1)
	tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1), 0.1)
