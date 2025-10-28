# layout_split.gd
extends Node2D

const ROOM_WIDTH = 720
const ROOM_HEIGHT = 320
const WALL_THICKNESS = 4

func _ready():
	create_label("SPLIT ROOM")
	create_middle_floor()

func create_label(text: String):
	var label = Label.new()
	label.text = text
	label.position = Vector2(ROOM_WIDTH / 2.0 - 60, 20)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.YELLOW)
	add_child(label)

func create_middle_floor():
	# Piso dividindo a sala ao meio
	var middle_floor = StaticBody2D.new()
	middle_floor.name = "MiddleFloor"
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(ROOM_WIDTH - (WALL_THICKNESS * 2), 4)
	collision.shape = shape
	collision.position = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT / 2.0)
	collision.one_way_collision = true
	
	var visual = ColorRect.new()
	visual.size = Vector2(ROOM_WIDTH - (WALL_THICKNESS * 2), 4)
	visual.color = Color(0.5, 0.3, 0.2)
	visual.position = Vector2(WALL_THICKNESS, ROOM_HEIGHT / 2.0 - 2)
	
	middle_floor.add_child(collision)
	middle_floor.add_child(visual)
	add_child(middle_floor)
