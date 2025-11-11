# layout_simple_01.gd
extends Node2D

const ROOM_WIDTH = 720
const ROOM_HEIGHT = 320

var rock_scene = preload("res://scenes/obstacles/rock.tscn")

func _ready():
	create_label("SIMPLE 01")
	create_obstacles()
	create_room_entry_detector()

func create_label(text: String):
	var label = Label.new()
	label.text = text
	label.position = Vector2(ROOM_WIDTH / 2.0 - 50, 20)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.WHITE)
	add_child(label)

func create_obstacles():
	create_rock(Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT - 20))

func create_rock(pos: Vector2):
	var rock = rock_scene.instantiate()
	rock.position = pos
	add_child(rock)

func create_room_entry_detector():
	"""Detecta quando o player entra na sala"""
	var detector = Area2D.new()
	detector.name = "EntryDetector"
	detector.collision_layer = 0
	detector.collision_mask = 1
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(ROOM_WIDTH, 40)
	collision.shape = shape
	collision.position = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT - 20)
	
	detector.add_child(collision)
	detector.body_entered.connect(_on_room_entered)
	add_child(detector)

func _on_room_entered(body):
	if body.name == "Player":
		GameManager.add_room()
		print("🎯 Sala alcançada!")
		get_node("EntryDetector").queue_free()
