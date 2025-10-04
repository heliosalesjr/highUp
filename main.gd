extends Node2D

func _ready():
	# Configura o chão placeholder se não existir
	if not has_node("Ground"):
		create_ground_placeholder()

func create_ground_placeholder():
	# Cria um chão simples para testes
	var ground = StaticBody2D.new()
	ground.name = "Ground"
	
	# Cria a colisão
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(800, 50)
	collision.shape = shape
	collision.position = Vector2(0, 25)
	
	# Cria o visual placeholder
	var visual = ColorRect.new()
	visual.size = Vector2(800, 50)
	visual.color = Color(0.4, 0.3, 0.2)  # Marrom
	visual.position = Vector2(-400, 0)
	
	ground.add_child(collision)
	ground.add_child(visual)
	ground.position = Vector2(400, 300)
	
	add_child(ground)
