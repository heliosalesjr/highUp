# mist.gd
extends Area2D

func _ready():
	add_to_group("collectible")  # Para o magnet funcionar
	collision_layer = 64
	collision_mask = 1

	body_entered.connect(_on_body_entered)
	create_idle_animation()

	print("🌫️ Mist powerup criado!")

func _on_body_entered(body):
	if body.name == "Player":
		GameManager.activate_mist_mode()
		print("🌫️ Mist coletado! Névoa ativada!")
		queue_free()

func create_idle_animation():
	"""Animação de flutuação"""
	var original_y = position.y
	_float(original_y)

func _float(original_y):
	if !is_inside_tree():
		return  # Evita erro caso esteja sendo destruído

	var tween = create_tween().bind_node(self)
	tween.set_loops(1)  # Executa só uma vez

	tween.tween_property(self, "position:y", original_y - 8, 0.6)
	tween.tween_property(self, "position:y", original_y + 8, 0.6)

	# Quando o ciclo terminar, chama de novo → animação infinita segura
	tween.tween_callback(func():
		_float(original_y)
	)
