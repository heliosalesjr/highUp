# layout_simple_03.gd
extends Node2D

const ROOM_WIDTH = 720
const ROOM_HEIGHT = 320

var slug_scene = preload("res://scenes/enemies/slug.tscn")

func _ready():
	create_label("SIMPLE 03")
	create_invisible_floor_for_enemies()
	create_enemies()
	create_room_entry_detector()

func create_label(text: String):
	var label = Label.new()
	label.text = text
	label.position = Vector2(ROOM_WIDTH / 2.0 - 50, 20)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.WHITE)
	add_child(label)

func create_invisible_floor_for_enemies():
	"""Cria um chão sólido invisível só para inimigos"""
	var enemy_floor = StaticBody2D.new()
	enemy_floor.name = "EnemyFloor"
	enemy_floor.collision_layer = 32
	enemy_floor.collision_mask = 0
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(ROOM_WIDTH, 4)
	collision.shape = shape
	collision.position = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT - 2)
	
	enemy_floor.add_child(collision)
	add_child(enemy_floor)

func create_enemies():
	var slug_height = 20
	var spawn_y = ROOM_HEIGHT - slug_height - 5
	create_slug(Vector2(ROOM_WIDTH / 2.0, spawn_y))

func create_slug(pos: Vector2):
	var slug = slug_scene.instantiate()
	slug.position = pos
	add_child(slug)

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
