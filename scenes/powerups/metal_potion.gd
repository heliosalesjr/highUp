# metal_potion.gd
extends Area2D

func _ready():
	# NÃO adiciona ao grupo collectible - powerups especiais não devem ser atraídos
	collision_layer = 64
	collision_mask = 1

	body_entered.connect(_on_body_entered)
	create_idle_animation()

	print("🛡️ Metal Potion criada!")

func _on_body_entered(body):
	if body.name == "Player" and body.has_method("activate_metal_mode"):
		body.activate_metal_mode()
		print("🛡️ Poção de Metal coletada!")
		queue_free()

func create_idle_animation():
	"""Animação de flutuação"""
	animate_float()

func animate_float():
	var tween = create_tween()
	var start_y = position.y
	
	tween.tween_property(self, "position:y", start_y - 8, 0.6)
	tween.tween_property(self, "position:y", start_y + 8, 0.6)
	tween.finished.connect(animate_float)
