# layout_saw_floor.gd
extends Node2D

const ROOM_WIDTH = 360
const ROOM_HEIGHT = 160

var sawblade_horizontal_scene = preload("res://scenes/obstacles/sawblade_horizontal.tscn")
var diamond_scene = preload("res://scenes/prize/diamond.tscn")
var heart_scene = preload("res://scenes/prize/heart.tscn")

func _ready():
	create_label("SAW FLOOR")
	spawn_sawblade_floor()
	spawn_prize_randomly()
	create_room_entry_detector()

func create_label(text: String):
	var label = Label.new()
	label.text = text
	label.position = Vector2(ROOM_WIDTH / 2.0 - 60, 20)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.ORANGE_RED)
	add_child(label)

func spawn_sawblade_floor():
	"""Spawna sawblade horizontal no chão, metade acima/metade abaixo"""
	var sawblade = sawblade_horizontal_scene.instantiate()
	
	# Posição: lado esquerdo, exatamente na altura do chão
	# O chão está em ROOM_HEIGHT (320), então colocamos a sawblade lá
	sawblade.position = Vector2(50, ROOM_HEIGHT)  # Y = 160 = altura do chão
	
	add_child(sawblade)
	print("🪚 Sawblade horizontal spawnada no chão em: ", sawblade.position)

func spawn_prize_randomly():
	"""50% de chance de spawnar um prêmio no centro-superior"""
	if randf() > 0.5:
		return
	
	# Prêmio no centro horizontal, mas na parte de cima para não pegar na sawblade
	var prize_position = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT / 3.0)
	
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
		print("🎯 Sala saw floor alcançada!")
		get_node("EntryDetector").queue_free()
