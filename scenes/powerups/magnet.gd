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
	var original_y = position.y
	_float(original_y)
	

func _float(original_y):
	if !is_inside_tree(): 
		return  # evita erro caso esteja sendo destruído

	var tween = create_tween().bind_node(self)
	tween.set_loops(1) # executa só uma vez
	
	tween.tween_property(self, "position:y", original_y - 8, 0.6)
	tween.tween_property(self, "position:y", original_y + 8, 0.6)

	# quando o ciclo terminar, chama de novo → animação infinita segura
	tween.tween_callback(func():
		_float(original_y)
	)
