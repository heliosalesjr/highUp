# magnet.gd
extends Area2D

func _ready():
	collision_layer = 64  # Layer de power-ups
	collision_mask = 1    # Detecta player
	
	body_entered.connect(_on_body_entered)
	
	# Animação de flutuação
	create_idle_animation()

func _on_body_entered(body):
	if body.name == "Player" and body.has_method("activate_magnet"):
		body.activate_magnet()
		print("🧲 Ímã coletado!")
		queue_free()

func create_idle_animation():
	"""Animação de flutuação"""
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y - 8, 0.6)
	tween.tween_property(self, "position:y", position.y + 8, 0.6)
