# heart.gd
extends Area2D

func _ready():
	collision_layer = 24
	collision_mask = 1
	
	body_entered.connect(_on_body_entered)
	create_idle_animation()

func _on_body_entered(body):
	if body.name == "Player":
		collect()

func collect():
	print("❤️ Coração coletado!")
	
	# Adiciona coração diretamente
	GameManager.add_heart()
	
	queue_free()

func create_idle_animation():
	"""Animação simples de flutuação"""
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y - 5, 0.5)
	tween.tween_property(self, "position:y", position.y + 5, 0.5)
