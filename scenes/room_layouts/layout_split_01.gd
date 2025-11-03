# layout_split_01.gd
extends Node2D

const ROOM_WIDTH = 720
const ROOM_HEIGHT = 320
const WALL_THICKNESS = 4

func _ready():
	create_label("SPLIT 01")
	create_middle_platform()

func create_label(text: String):
	var label = Label.new()
	label.text = text
	label.position = Vector2(ROOM_WIDTH / 2.0 - 60, 20)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.YELLOW)
	add_child(label)

func create_middle_platform():
	# Plataforma com 1/3 da largura, centralizada
	var platform_width = ROOM_WIDTH / 3.0
	var platform_x = ROOM_WIDTH / 2.0  # Centro horizontal
	
	var middle_platform = StaticBody2D.new()
	middle_platform.name = "MiddlePlatform"
	middle_platform.collision_layer = 16
	middle_platform.collision_mask = 0
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(platform_width, 4)
	collision.shape = shape
	collision.position = Vector2(platform_x, ROOM_HEIGHT / 2.0)
	collision.one_way_collision = true
	
	var visual = ColorRect.new()
	visual.size = Vector2(platform_width, 4)
	visual.color = Color(0.5, 0.3, 0.2)
	# Centraliza o visual (já que ColorRect começa do canto)
	visual.position = Vector2(platform_x - platform_width / 2.0, ROOM_HEIGHT / 2.0 - 2)
	
	middle_platform.add_child(collision)
	middle_platform.add_child(visual)
	add_child(middle_platform)
