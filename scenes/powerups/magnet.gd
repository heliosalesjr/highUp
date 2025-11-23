# magnet.gd
extends Area2D

func _ready():
	collision_layer = 64
	collision_mask = 1
	
	body_entered.connect(_on_body_entered)
	create_idle_animation()

func _on_body_entered(body):
	if body.name == "Player" and body.has_method("activate_magnet"):
		body.activate_magnet()
		print("🧲 Ímã coletado!")
		queue_free()

func create_idle_animation():
	"""Animação de flutuação"""
	var tween = create_tween()
	tween.set_loops(0)  # ← 0 = infinito, mas funciona diferente
	
	# Usa approach diferente para evitar o erro
	var original_y = position.y
	tween.tween_property(self, "position:y", original_y - 8, 0.6)
	tween.tween_property(self, "position:y", original_y + 8, 0.6)
