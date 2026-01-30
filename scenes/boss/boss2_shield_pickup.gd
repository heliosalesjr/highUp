# boss2_shield_pickup.gd
extends Area2D

signal pickup_collected

const SIZE = 20

func _ready():
	collision_layer = 0
	collision_mask = 1  # Detect player body
	monitoring = true

	# Visual: blue/cyan rectangle
	var visual = ColorRect.new()
	visual.size = Vector2(SIZE, SIZE)
	visual.position = Vector2(-SIZE / 2.0, -SIZE / 2.0)
	visual.color = Color(0.2, 0.6, 1.0)
	add_child(visual)

	# Collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(SIZE, SIZE)
	collision.shape = shape
	add_child(collision)

	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		pickup_collected.emit()
		queue_free()
