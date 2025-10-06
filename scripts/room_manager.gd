extends Node

func populate_room(room: Node2D, room_index: int):
	"""Popula uma sala com obstáculos"""
	
	if room_index == 0:
		return
	
	# 50% de chance de ter spike
	if randf() > 0.5:
		return
	
	# Descobre qual lado a escada está
	var ladder = room.get_node_or_null("Ladder")
	var ladder_on_right = true
	if ladder:
		# Se a escada está à esquerda (X < 360)
		ladder_on_right = ladder.position.x > 360
	
	# Define zona segura para spike (longe da escada)
	var safe_x_min = 100
	var safe_x_max = 620
	
	if ladder_on_right:
		# Escada à direita, spike vai à esquerda
		safe_x_max = 400
	else:
		# Escada à esquerda, spike vai à direita
		safe_x_min = 320
	
	# Cria spike
	var spike = Area2D.new()
	spike.name = "Spike"
	spike.collision_layer = 4
	spike.collision_mask = 1
	
	# Visual
	var visual = ColorRect.new()
	visual.size = Vector2(40, 20)
	visual.color = Color.RED
	visual.position = Vector2(-20, -10)
	spike.add_child(visual)
	
	# Collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(40, 20)
	collision.shape = shape
	spike.add_child(collision)
	
	# Posição: próximo ao chão (Y = 300) e longe da escada
	var spike_x = randi_range(safe_x_min, safe_x_max)
	var spike_y = 300  # Próximo ao chão que está em Y=320
	spike.position = Vector2(spike_x, spike_y)
	
	# Conecta sinal de colisão
	spike.body_entered.connect(_on_spike_hit.bind(spike))
	
	room.add_child(spike)
	print("  ✓ Spike em Room ", room_index, " pos X=", spike_x)

func _on_spike_hit(body: Node2D, _spike: Area2D):
	"""Callback quando player toca no spike"""
	if body.name == "Player":
		print("💀 PLAYER MORREU! Tocou em spike")
		# Aqui você vai adicionar lógica de morte depois
		# Por enquanto só printa
