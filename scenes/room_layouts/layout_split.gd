# layout_split.gd
extends Node2D

const ROOM_WIDTH = 720
const ROOM_HEIGHT = 320
const WALL_THICKNESS = 4

var diamond_scene = preload("res://scenes/prize/diamond.tscn")
var heart_scene = preload("res://scenes/prize/heart.tscn")
var metal_potion_scene = preload("res://scenes/powerups/metal_potion.tscn")

func _ready():
	create_label("SPLIT ROOM")
	create_middle_floor()
	spawn_prize_randomly()
	create_room_entry_detector()
	create_second_floor_detector()

func create_label(text: String):
	var label = Label.new()
	label.text = text
	label.position = Vector2(ROOM_WIDTH / 2.0 - 60, 20)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.YELLOW)
	add_child(label)

func create_middle_floor():
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

func create_room_entry_detector():
	"""Detecta quando o player ENTRA na sala split"""
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

func create_second_floor_detector():
	"""Detecta quando o player alcança o piso do MEIO (segundo andar)"""
	var detector = Area2D.new()
	detector.name = "SecondFloorDetector"
	detector.collision_layer = 0
	detector.collision_mask = 1
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(ROOM_WIDTH - 100, 30)
	collision.shape = shape
	collision.position = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT / 2.0 - 30)
	
	detector.add_child(collision)
	detector.body_entered.connect(_on_second_floor_reached)
	add_child(detector)

func _on_room_entered(body):
	if body.name == "Player":
		GameManager.add_room()
		print("🎯 Sala split alcançada! (+1)")
		get_node("EntryDetector").queue_free()

func _on_second_floor_reached(body):
	if body.name == "Player":
		GameManager.add_room()
		print("🎯 Segundo piso alcançado! (+1)")
		get_node("SecondFloorDetector").queue_free()

func spawn_prize_randomly():
	"""50% de chance de spawnar um prêmio"""
	if randf() > 0.5:
		return
	
	var prize_position = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT / 2.0 - 40)
	
	# Prioridade: Metal Potion > Heart > Diamond
	if GameManager.can_spawn_metal_potion():
		var potion = metal_potion_scene.instantiate()  # ← Adicione preload no topo
		potion.position = prize_position
		add_child(potion)
		print("🛡️ Poção de Metal spawnada!")
	elif GameManager.can_spawn_heart():
		var heart = heart_scene.instantiate()
		heart.position = prize_position
		add_child(heart)
		print("❤️ Coração spawnado!")
	else:
		var diamond = diamond_scene.instantiate()
		diamond.position = prize_position
		add_child(diamond)
		print("💎 Diamante spawnado!")
