# layout_capy.gd
extends Node2D

const ROOM_WIDTH = 360
const ROOM_HEIGHT = 160

var capy_scene = preload("res://scenes/enemies/capy.tscn")

func _ready():
	create_invisible_floor_for_enemies()
	create_enemies()
	create_room_entry_detector()

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
	var capy_height = 20
	var spawn_y = ROOM_HEIGHT - capy_height - 5
	create_capy(Vector2(ROOM_WIDTH / 2.0, spawn_y))

func create_capy(pos: Vector2):
	var capy = capy_scene.instantiate()
	capy.position = pos
	add_child(capy)

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
		print("🦫 Sala da Capy alcançada!")
		get_node("EntryDetector").queue_free()
