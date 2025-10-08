extends Area2D
class_name ObstacleBase

# Classe base para todos os obstáculos

signal player_hit

var damage: int = 1

func _ready():
	collision_layer = 4  # Layer de obstáculos
	collision_mask = 1   # Detecta player
	body_entered.connect(_on_body_entered)
	setup()

func setup():
	"""Sobrescrever em classes filhas para criar visual e colisão"""
	pass

func _on_body_entered(body: Node2D):
	if body.name == "Player":
		on_player_hit(body)

func on_player_hit(player: Node2D):
	"""Sobrescrever para lógica específica"""
	player_hit.emit()
	print("💀 Player hit obstacle!")
