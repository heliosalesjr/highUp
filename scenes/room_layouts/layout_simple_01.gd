# layout_simple_01.gd
extends Node2D

const ROOM_WIDTH = 720
const ROOM_HEIGHT = 320

func _ready():
	create_label("SIMPLE 01")
	create_obstacles()

func create_label(text: String):
	var label = Label.new()
	label.text = text
	label.position = Vector2(ROOM_WIDTH / 2.0 - 50, 20)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.WHITE)
	add_child(label)

func create_obstacles():
	# Apenas 1 spike no centro do chão
	create_spike(Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT - 30))

func create_spike(pos: Vector2):
	var spike = Area2D.new()
	spike.name = "Spike"
	spike.collision_layer = 4
	spike.collision_mask = 1
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(20, 20)
	collision.shape = shape
	
	var visual = Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-10, 10),
		Vector2(10, 10),
		Vector2(0, -10)
	])
	visual.color = Color(0.8, 0.1, 0.1)
	
	spike.add_child(collision)
	spike.add_child(visual)
	spike.position = pos
	add_child(spike)
