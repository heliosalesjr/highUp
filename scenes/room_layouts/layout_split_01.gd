# layout_split_01.gd
extends Node2D

const ROOM_WIDTH = 360
const ROOM_HEIGHT = 160
const WALL_THICKNESS = 6  # ← Atualizado para pixel art (paredes laterais)
const FLOOR_THICKNESS = 6  # ← Atualizado para pixel art

var diamond_scene = preload("res://scenes/prize/diamond.tscn")
var heart_scene = preload("res://scenes/prize/heart.tscn")

func _ready():
	# create_label("SPLIT 01")  # Hidden for now
	create_middle_platform()
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

func create_middle_platform():
	var platform_width = ROOM_WIDTH / 3.0
	var platform_x = (ROOM_WIDTH - platform_width) / 2.0

	var middle_platform = StaticBody2D.new()
	middle_platform.name = "MiddlePlatform"

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	# Collision shape bem fina no TOPO do piso (1 pixel)
	shape.size = Vector2(platform_width, 1)
	collision.shape = shape
	# Posiciona no topo do floor visual (linha mais alta)
	collision.position = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT / 2.0 - FLOOR_THICKNESS / 2.0)
	collision.one_way_collision = true

	# SIMULAÇÃO VISUAL: Floor com cor única para referência de espessura
	var visual = ColorRect.new()
	visual.size = Vector2(platform_width, FLOOR_THICKNESS)
	visual.color = Color(0.4, 0.25, 0.15)  # Marrom terra
	visual.position = Vector2(platform_x, ROOM_HEIGHT / 2.0 - FLOOR_THICKNESS / 2.0)

	middle_platform.add_child(collision)
	middle_platform.add_child(visual)
	add_child(middle_platform)

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
	"""50% de chance de spawnar um prêmio (diamante ou coração)"""
	if randf() > 0.5:
		return
	
	var prize_position = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT / 2.0 - 40)
	
	# Verifica se deve spawnar coração ou diamante
	if GameManager.can_spawn_heart():
		var heart = heart_scene.instantiate()
		heart.position = prize_position
		add_child(heart)
		print("❤️ Coração spawnado!")
	else:
		var diamond = diamond_scene.instantiate()
		diamond.position = prize_position
		add_child(diamond)
		print("💎 Diamante spawnado!")
